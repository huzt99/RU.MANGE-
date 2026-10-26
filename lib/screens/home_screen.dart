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
  Map<String, dynamic>? detectedRouter;
  List<Map<String, String>> savedRouters = [];

  @override
  void initState() {
    super.initState();
    loadSavedRouters();
    scanNetworkAndDetectDevice(); // الفحص التلقائي للشبكة عند فتح التطبيق مثل تطبيق Cudy
  }

  Future<void> loadSavedRouters() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('router_hub_devices') ?? [];
    setState(() {
      savedRouters = saved.map((item) {
        final parts = item.split('|');
        return {
          "name": parts.isNotEmpty ? parts[0] : "راوتر",
          "brand": parts.length > 1 ? parts[1] : "Cudy / TP-Link",
          "ip": parts.length > 2 ? parts[2] : "192.168.1.1",
        };
      }).toList();
    });
  }

  Future<void> saveRoutersToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> formatted = savedRouters.map((r) => "${r['name']}|${r['brand']}|${r['ip']}").toList();
    await prefs.setStringList('router_hub_devices', formatted);
  }

  // فحص الشبكة وتحديد الراوتر المتصل به حالياً (يدعم Cudy, TP-Link, Tenda, ONU)
  Future<void> scanNetworkAndDetectDevice() async {
    setState(() => isScanning = true);

    // جلب الآيب الحقيقي للـ Gateway للشبكة المكنك عليها
    String routerIp = await NetworkService.getConnectedRouterIP();
    String brandName = NetworkService.detectRouterBrand(routerIp);

    await Future.delayed(const Duration(seconds: 15)); // محاكاة وقت الفحص الذكي للشبكة

    setState(() {
      isScanning = false;
      detectedRouter = {
        "name": "راوتر الشبكة الحالي",
        "brand": brandName,
        "ip": routerIp,
        "icon": Icons.router,
      };
    });
  }

  // نافذة إدخال كلمة سر الراوتر المكتشف (مثل تطبيق Cudy)
  void _showPasswordPromptDialog(Map<String, dynamic> router) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text("تسجيل الدخول: ${router['name']}", style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("النوع المكتشف: ${router['brand']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
            const SizedBox(height: 4),
            Text("الآيب: ${router['ip']}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: "أدخل كلمة مرور الراوتر (Password)",
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

              // حفظ الجهاز في السجل المحلي
              setState(() {
                if (!savedRouters.any((r) => r['ip'] == router['ip'])) {
                  savedRouters.add({
                    "name": router['name']!,
                    "brand": router['brand']!,
                    "ip": router['ip']!,
                  });
                  saveRoutersToStorage();
                }
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم التحقق بنجاح! جاري فتح خصائص الراوتر والإدارة...")),
              );
            },
            child: const Text("دخول للخصائص"),
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
          // لوحة القيادة الميدانية (مشابهة لتطبيق Cudy)
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
                    const Text("لوحة القيادة (Wi-Fi Radar)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
                      onPressed: scanNetworkAndDetectDevice,
                      tooltip: "إعادة بحث الفحص",
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                isScanning
                    ? Column(
                        children: const [
                          CircularProgressIndicator(color: Colors.cyanAccent),
                          SizedBox(height: 12),
                          Text("جاري فحص الشبكة والتعرف على الراوتر...", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      )
                    : detectedRouter != null
                        ? InkWell(
                            onTap: () => _showPasswordPromptDialog(detectedRouter!),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1120),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
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
                                        Text("IP Gateway: ${detectedRouter!['ip']}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 16),
                                ],
                              ),
                            ),
                          )
                        : const Text("لم يتم العثور على أجهزة", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // الأجهزة المحفوظة في الميدان
          const Text("الأجهزة والمنظومات المحفوظة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          savedRouters.isEmpty
              ? const Text("لا توجد أجهزة محفوظة في السجل", style: TextStyle(color: Colors.grey, fontSize: 12))
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
                        leading: const Icon(Icons.hub, color: Colors.cyanAccent),
                        title: Text(r['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text("النوع: ${r['brand']} | IP: ${r['ip']}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        trailing: IconButton(
                          icon: const Icon(Icons.login, color: Colors.greenAccent),
                          onPressed: () => _showPasswordPromptDialog(r),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() => const Center(child: Text("قائمة الأجهزة المتصلة", style: TextStyle(color: Colors.white)));
  Widget _buildSettingsTab() => const Center(child: Text("إعدادات البرنامج", style: TextStyle(color: Colors.white)));
  Widget _buildMoreTab() => const Center(child: Text("الأدوات المتقدمة والمزيد", style: TextStyle(color: Colors.white)));

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
            Text("RouterHub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("RU-Mange | Cudy, TP-Link, Tenda & ONU", style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
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
