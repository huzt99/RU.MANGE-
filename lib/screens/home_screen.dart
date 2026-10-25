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
  List<Map<String, String>> routersList = [];
  bool isScanning = true;
  String discoveredIp = "192.168.1.1";
  int selectedRouterIndex = 0;

  @override
  void initState() {
    super.initState();
    loadRoutersFromStorage();
    scanNetworkGateway();
  }

  Future<void> loadRoutersFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('saved_routers') ?? [];
    
    setState(() {
      if (saved.isNotEmpty) {
        routersList = saved.map((item) {
          final parts = item.split('|');
          return {
            "name": parts.isNotEmpty ? parts[0] : "مشترك",
            "ip": parts.length > 1 ? parts[1] : "192.168.1.1",
            "type": parts.length > 2 ? parts[2] : "راوتر",
            "user": parts.length > 3 ? parts[3] : "admin",
            "pass": parts.length > 4 ? parts[4] : "admin",
          };
        }).toList();
      }
    });
  }

  Future<void> saveRoutersToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> formatted = routersList.map((r) => "${r['name']}|${r['ip']}|${r['type']}|${r['user']}|${r['pass']}").toList();
    await prefs.setStringList('saved_routers', formatted);
  }

  Future<void> scanNetworkGateway() async {
    setState(() => isScanning = true);
    String ip = await NetworkService.discoverRouterIP();
    setState(() {
      isScanning = false;
      discoveredIp = ip;
    });
  }

  void showAddRouterDialog(String detectedIp) {
    final nameController = TextEditingController(text: "مشترك ميداني جديد");
    final ipController = TextEditingController(text: detectedIp);
    final userController = TextEditingController(text: "admin");
    final passController = TextEditingController(text: "admin");
    String selectedBrand = 'TP-Link (جميع الأصناف)';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF131C31),
          title: const Row(
            children: [
              Icon(Icons.router, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Text("إضافة وحفظ جهاز الميدان", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "اسم المشترك أو الموقع", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ipController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "آيب الراوتر أو البوابة (Gateway)", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedBrand,
                  dropdownColor: const Color(0xFF131C31),
                  style: const TextStyle(color: Colors.white),
                  items: [
                    'TP-Link (جميع الأصناف)',
                    'Deco (MESH بجميع الأصناف)',
                    'Cudy (جميع الأصناف)',
                    'D-Link (جميع الأصناف)',
                    'Honor / Huawei راوتر',
                    'راوتر ضوئي ONT / ONU',
                    'نانو / Ubiquiti / MikroTik',
                    'آيب مخصص / Static'
                  ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedBrand = val!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: userController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "اسم المستخدم (Admin User)", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "كلمة المرور (Password)", labelStyle: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              onPressed: () {
                if (nameController.text.isEmpty) return;
                setState(() {
                  routersList.add({
                    "name": nameController.text,
                    "ip": ipController.text,
                    "type": selectedBrand,
                    "user": userController.text,
                    "pass": passController.text,
                  });
                  selectedRouterIndex = routersList.length - 1;
                });
                saveRoutersToStorage();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم حفظ الجهاز وظهوره في القائمة العلوية بنجاح!")),
                );
              },
              child: const Text("حفظ ودخول"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRouter = routersList.isNotEmpty ? routersList[selectedRouterIndex] : {"name": "لا يوجد جهاز", "ip": discoveredIp, "type": "غير محدد", "user": "admin", "pass": "admin"};

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
          onPressed: scanNetworkGateway,
          tooltip: "تحديث الشبكة",
        ),
        title: Column(
          children: const [
            Text("RouterHub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("راوترهب | إدارة الراوترات والـ ONU", style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
            onPressed: () => showAddRouterDialog(discoveredIp),
            tooltip: "إضافة جهاز جديد",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("الراوترات والمنظومات المحفوظة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${routersList.length} أجهزة", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),

            // القائمة العلوية الأفقية للراوترات والأجهزة المحفوظة
            SizedBox(
              height: 100,
              child: routersList.isEmpty
                  ? const Center(child: Text("لا توجد أجهزة مسجلة، اضغط (+) لإضافة جهاز", style: TextStyle(color: Colors.grey, fontSize: 12)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: routersList.length,
                      itemBuilder: (context, index) {
                        final r = routersList[index];
                        bool isSelected = index == selectedRouterIndex;

                        return GestureDetector(
                          onTap: () => setState(() => selectedRouterIndex = index),
                          child: Container(
                            width: 135,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF131C31),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? Colors.cyanAccent : Colors.white12,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.router, color: Colors.cyanAccent, size: 22),
                                    if (isSelected) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  r["name"]!,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(r["ip"]!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // بطاقة التحكم بالجهاز النشط الحالي والوصول للـ ONU / النانو
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
                      Text("إدارة: ${activeRouter['name']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("IP: ${activeRouter['ip']}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 105,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1120),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hub, color: Colors.cyanAccent, size: 32),
                        const SizedBox(height: 6),
                        Text("النوع: ${activeRouter['type']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(height: 2),
                        const Text("جاهز للتحكم بالراوتر والوصول للـ ONU / النانو", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                      icon: const Icon(Icons.login, size: 16),
                      label: Text("الدخول لصفحة الراوتر والـ ONU (${activeRouter['ip']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF131C31),
                            title: Text("بوابة الوصول: ${activeRouter['name']}", style: const TextStyle(color: Colors.white)),
                            content: Text("الآيب (${activeRouter['ip']}) يتيح لك الدخول لإدارة الراوتر، ومن خلال إعدادات الـ WAN أو البوابة تستطيع الوصول المباشر للـ ONU أو النانو المرتبط.\n\nمعلومات الدخول المحفوظة:\nالمستخدم: ${activeRouter['user']}\nكلمة المرور: ••••••••", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("فتح المتصفح على الـ IP: ${activeRouter['ip']} ...")),
                                  );
                                },
                                child: const Text("فتح صفحة الأدمين"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // أزرار التحكم الميداني الأربعة
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildActionCard("إدارة الشبكة", "Manage Network", Icons.tune, Colors.cyanAccent, () {
                  showAddRouterDialog(discoveredIp);
                }),
                _buildActionCard("شبكة الضيوف", "Guest Network", Icons.people_outline, Colors.purpleAccent, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("إعدادات شبكة الضيوف")));
                }),
                _buildActionCard("التحكم الأبوي", "Parental Control", Icons.lock_outline, Colors.orangeAccent, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("إعدادات التحكم الأبوي")));
                }),
                _buildActionCard("اختبار السرعة", "Speed Test", Icons.speed, Colors.greenAccent, () {
                  scanNetworkGateway();
                }),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildActionCard(String titleAr, String titleEn, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF131C31),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titleAr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 4),
            Text(titleEn, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
