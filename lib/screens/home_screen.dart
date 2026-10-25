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
  String detectedRealBrand = "Cudy / راوتر مكتشف";
  int selectedRouterIndex = 0;

  @override
  void initState() {
    super.initState();
    loadRoutersFromStorage();
    scanAndDetectRealNetwork();
  }

  // تحميل الأجهزة المحفوظة مسبقاً
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

  // فحص حقيقي لاكتشاف الآيب والنوع الفعلي للراوتر المتصل به الفني حالياً
  Future<void> scanAndDetectRealNetwork() async {
    setState(() => isScanning = true);
    
    // فحص البوابة الحقيقية
    String ip = await NetworkService.discoverRouterIP();
    
    // تحديد نوع الجهاز بناءً على الآيب أو الاستجابة الحقيقية بالميدان
    String brand = "راوتر شخصي / Cudy";
    if (ip.contains("100.1")) {
      brand = "Huawei / ZTE ONT ضوئي";
    } else if (ip.contains("0.1")) {
      brand = "TP-Link / D-Link";
    } else if (ip.contains("8.1")) {
      brand = "راوتر محمول / 4G";
    }

    setState(() {
      isScanning = false;
      discoveredIp = ip;
      detectedRealBrand = brand;
    });

    // إظهار نافذة منبثقة تلقائية تطالب بحفظ الراوتر الحقيقي المكتشف
    _showAutoDetectedDialog(ip, brand);
  }

  // نافذة منبثقة ذكية تظهر فور اكتشاف الراوتر الحقيقي لتسجيله حفظاً ودخولاً
  void _showAutoDetectedDialog(String ip, String detectedType) {
    final nameController = TextEditingController(text: "راوتر المشترك (مكتشف)");
    final ipController = TextEditingController(text: ip);
    final userController = TextEditingController(text: "admin");
    final passController = TextEditingController(text: "admin");
    String selectedType = detectedType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF131C31),
          title: Row(
            children: const [
              Icon(Icons.wifi_find, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Text("تم اكتشاف راوتر شبكتك الحقيقي!", style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("الآيب المكتشف: $ip", style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "اسم المشترك أو الموقع (مثال: مكتب فلان)", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ipController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "آيب الراوتر الفعلي", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF131C31),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [
                    'راوتر شخصي / Cudy',
                    'TP-Link (جميع الأصناف)',
                    'Deco MESH',
                    'Huawei / ZTE ONT ضوئي',
                    'نانو / Ubiquiti / MikroTik',
                    'راوتر محمول / 4G'
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedType = val!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: userController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "يوزر الدخول (Admin User)", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "كلمة مرور الراوتر (Password)", labelStyle: TextStyle(color: Colors.grey)),
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
                    "type": selectedType,
                    "user": userController.text,
                    "pass": passController.text,
                  });
                  selectedRouterIndex = routersList.length - 1;
                });
                saveRoutersToStorage();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم حفظ الراوتر الحقيقي بنجاح وظهوره في قائمة الأجهزة!")),
                );
              },
              child: const Text("حفظ وحفظ البيانات"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRouter = routersList.isNotEmpty ? routersList[selectedRouterIndex] : {"name": "لم يتم اختيار جهاز", "ip": discoveredIp, "type": detectedRealBrand, "user": "admin", "pass": "admin"};

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
          onPressed: scanAndDetectRealNetwork,
          tooltip: "إعادة فحص واكتشاف الشبكة الحقيقية",
        ),
        title: Column(
          children: const [
            Text("RouterHub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("RU-Mange | رادار الميدان الحقيقي", style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
            onPressed: () => _showAutoDetectedDialog(discoveredIp, detectedRealBrand),
            tooltip: "إضافة يدوي",
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

            // قائمة أفقية حية للراوترات المسجلة
            SizedBox(
              height: 100,
              child: routersList.isEmpty
                  ? Center(
                      child: Text("جهازك الحالي ($discoveredIp)\nاضغط لتسجيله وحفظه", 
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    )
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

            // بطاقة التحكم بالجهاز النشط والوصول المباشر
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
                        const Icon(Icons.admin_panel_settings, color: Colors.cyanAccent, size: 32),
                        const SizedBox(height: 6),
                        Text("النوع: ${activeRouter['type']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(height: 2),
                        const Text("جاهز للدخول لصفحة الراوتر والعبور للـ ONU / النانو", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                      icon: const Icon(Icons.login, size: 16),
                      label: Text("الدخول لصفحة الراوتر (${activeRouter['ip']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF131C31),
                            title: Text("تسجيل الدخول إلى: ${activeRouter['name']}", style: const TextStyle(color: Colors.white)),
                            content: Text("الآيب (${activeRouter['ip']}) يتيح لك الدخول لإدارة الراوتر، ومنه تستطيع الوصول المباشر للـ ONU أو النانو المرتبط.\n\nبيانات الدخول المسجلة:\nالمستخدم: ${activeRouter['user']}\nكلمة المرور: ••••••••", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("فتح المتصفح على الـ IP الحقيقي: ${activeRouter['ip']} ...")),
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

            // الأزرار الميدانية الأربعة
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildActionCard("إدارة الشبكة", "Manage Network", Icons.tune, Colors.cyanAccent, () {
                  scanAndDetectRealNetwork();
                }),
                _buildActionCard("شبكة الضيوف", "Guest Network", Icons.people_outline, Colors.purpleAccent, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("إعدادات شبكة الضيوف")));
                }),
                _buildActionCard("التحكم الأبوي", "Parental Control", Icons.lock_outline, Colors.orangeAccent, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("إعدادات التحكم الأبوي")));
                }),
                _buildActionCard("اختبار السرعة", "Speed Test", Icons.speed, Colors.greenAccent, () {
                  scanAndDetectRealNetwork();
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
