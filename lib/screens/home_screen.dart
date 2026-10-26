import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ru_mange/services/network_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool isScanning = false;
  bool isCloudSynced = false;
  Map<String, dynamic>? detectedRouter;
  List<Map<String, String>> savedRouters = [];

  @override
  void initState() {
    super.initState();
    loadSavedRouters();
    scanNetworkAndDetectDevice();
  }

  Future<void> loadSavedRouters() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('router_hub_devices_cloud') ?? [];
    setState(() {
      savedRouters = saved.map((item) {
        final parts = item.split('|');
        return {
          "name": parts.isNotEmpty ? parts[0] : "راوتر",
          "brand": parts.length > 1 ? parts[1] : "Cudy / TP-Link",
          "ip": parts.length > 2 ? parts[2] : "192.168.1.1",
          "status": parts.length > 3 ? parts[3] : "محلي وسحابي",
        };
      }).toList();
    });
  }

  Future<void> syncRouterToCloud(String name, String brand, String ip) async {
    setState(() => isCloudSynced = true);

    bool success = await NetworkService.saveRouterToCloud({
      "name": name,
      "brand": brand,
      "ip": ip,
      "timestamp": DateTime.now().toString(),
    });

    setState(() {
      if (!savedRouters.any((r) => r['ip'] == ip)) {
        savedRouters.add({
          "name": name,
          "brand": brand,
          "ip": ip,
          "status": success ? "متزامن مع JSONBin ☁️" : "محلي فقط",
        });
      }
      isCloudSynced = false;
    });

    final prefs = await SharedPreferences.getInstance();
    List<String> formatted = savedRouters.map((r) => "${r['name']}|${r['brand']}|${r['ip']}|${r['status']}").toList();
    await prefs.setStringList('router_hub_devices_cloud', formatted);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "تم حفظ البيانات على حسابك السحابي بنجاح! ☁️" : "تم الحفظ محلياً (تعذر الاتصال بالسيرفر)")),
    );
  }

  Future<void> scanNetworkAndDetectDevice() async {
    setState(() => isScanning = true);
    String routerIp = await NetworkService.getConnectedRouterIP();
    String brandName = NetworkService.detectRouterBrand(routerIp);

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isScanning = false;
      detectedRouter = {
        "name": "راوتر الشبكة الحالي",
        "brand": brandName,
        "ip": routerIp,
      };
    });
  }

  void _showPasswordAndCloudSyncDialog(Map<String, dynamic> router) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        title: Row(
          children: [
            const Icon(Icons.cloud_sync, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text("إدارة سحابية: ${router['name']}", style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("النوع: ${router['brand']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
            const SizedBox(height: 4),
            Text("الآيب: ${router['ip']}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
            const SizedBox(height: 8),
            const Text("حفظ البيانات يتيح لك التحكم بالجهاز عن بعد.", style: TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: "كلمة مرور الأدمين (Password)",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              if (passwordController.text.isEmpty) return;
              Navigator.pop(context);
              syncRouterToCloud(router['name'], router['brand'], router['ip']);
            },
            child: const Text("حفظ سحابياً ودخول"),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131C31),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("لوحة التحكم السحابية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: [
                        const Icon(Icons.cloud_done, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 4),
                        const Text("JSONBin متصل", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                isScanning || isCloudSynced
                    ? Column(
                        children: const [
                          CircularProgressIndicator(color: Colors.cyanAccent),
                          SizedBox(height: 10),
                          Text("جاري المزامنة مع حسابك...", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      )
                    : detectedRouter != null
                        ? InkWell(
                            onTap: () => _showPasswordAndCloudSyncDialog(detectedRouter!),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1120),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.router, color: Colors.cyanAccent, size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(detectedRouter!['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text(detectedRouter!['brand'], style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                                        Text("الآيب: ${detectedRouter!['ip']}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.cloud_upload, color: Colors.cyanAccent, size: 20),
                                ],
                              ),
                            ),
                          )
                        : const Text("لا توجد أجهزة مكتشفة", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("الراوترات المحفوظة سحابياً", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          savedRouters.isEmpty
              ? const Text("لا توجد أجهزة مسجلة", style: TextStyle(color: Colors.grey, fontSize: 12))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: savedRouters.length,
                  itemBuilder: (context, index) {
                    final r = savedRouters[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131C31),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.cloud_queue, color: Colors.cyanAccent),
                        title: Text(r['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text("IP: ${r['ip']} | ${r['status']}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        trailing: IconButton(
                          icon: const Icon(Icons.settings_remote, color: Colors.greenAccent),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("جاري الاتصال بحسابك للتحكم في ${r['name']}...")),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() => const Center(child: Text("إدارة الأجهزة عن بعد", style: TextStyle(color: Colors.white)));
  Widget _buildSettingsTab() => const Center(child: Text("إعدادات الحساب السحابي", style: TextStyle(color: Colors.white)));
  Widget _buildMoreTab() => const Center(child: Text("أدوات الميدان", style: TextStyle(color: Colors.white)));

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [
      _buildHomeTab(),
      _buildDevicesTab(),
      _buildSettingsTab(),
      _buildMoreTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          children: const [
            Text("RouterHub Cloud", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("RU-Mange | JSONBin Connected", style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
          ],
        ),
        centerTitle: true,
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B1120),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "رئيسية"),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: "الأجهزة"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "الإعدادات"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "المزيد"),
        ],
      ),
    );
  }
}
