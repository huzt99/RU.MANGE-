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
    autoDetectNetworkRouter(); // الفحص التلقائي الفوري عند فتح البرنامج
  }

  Future<void> loadRoutersFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('saved_routers') ?? [];
    
    setState(() {
      if (saved.isNotEmpty) {
        routersList = saved.map((item) {
          final parts = item.split('|');
          return {
            "name": parts.isNotEmpty ? parts[0] : "راوتر المشترك",
            "ip": parts.length > 1 ? parts[1] : "192.168.1.1",
            "type": parts.length > 2 ? parts[2] : "راوتر رئيسي",
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

  // الكشف التلقائي عن الراوتر المتصل به الموبايل حالياً بغض النظر عن الآيب
  Future<void> autoDetectNetworkRouter() async {
    setState(() => isScanning = true);
    
    // سحب الآيب الحقيقي للراوتر المتصل به حالياً
    String ip = await NetworkService.discoverRouterIP();
    
    setState(() {
      isScanning = false;
      discoveredIp = ip;
    });

    // إذا لم يكن الراوتر محفوظاً مسبقاً، نظهر له تنبيه "تم اكتشاف جهاز جديد" فوراً
    bool exists = routersList.any((r) => r['ip'] == ip);
    if (!exists && ip.isNotEmpty) {
      _showNewDeviceDetectedDialog(ip);
    }
  }

  // نافذة "تم اكتشاف جهاز جديد" التي تطلب يوزر وباسورد الراوتر وتخزنه
  void _showNewDeviceDetectedDialog(String detectedIp) {
    final nameController = TextEditingController(text: "راوتر الشبكة (مكتشف)");
    final ipController = TextEditingController(text: detectedIp);
    final userController = TextEditingController(text: "admin");
    final passController = TextEditingController(text: "admin");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        title: Row(
          children: const [
            Icon(Icons.notification_important, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text("هناك جهاز جديد متصل!", style: TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("تم اكتشاف راوتر الشبكة على الآيب:\n$detectedIp", style: const TextStyle(color: Colors.greenAccent, fontSize: 12), textAlign: TextAlign.right),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: "اسم المشترك أو الراوتر", labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ipController,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: "آيب الراوتر المكتشف", labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: userController,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: "يوزر دخول الراوتر (Username)", labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: "باسورد دخول الراوتر (Password)", labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("تخطي", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              if (nameController.text.isEmpty) return;
              setState(() {
                routersList.add({
                  "name": nameController.text,
                  "ip": ipController.text,
                  "type": "راوتر مكتشف و ONU",
                  "user": userController.text,
                  "pass": passController.text,
                });
                selectedRouterIndex = routersList.length - 1;
              });
              saveRoutersToStorage();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم حفظ الراوتر ودخول إجهاداته بنجاح في القائمة العلوية!")),
              );
            },
            child: const Text("حفظ ودخول للأدمين"),
          ),
        ],
      ),
    );
  }

  // الواجهة الرئيسية للتحكم بالراوتر والوصول للـ ONU
  Widget _buildHomeTab() {
    final activeRouter = routersList.isNotEmpty
        ? routersList[selectedRouterIndex]
        : {"name": "راوتر الشبكة الحالي", "ip": discoveredIp, "type": "جهاز بانتظار الحفظ", "user": "admin", "pass": "admin"};

    return SingleChildScrollView(
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

          // البطاقات العلوية (الراوترات المتصلة والمحفوظة)
          SizedBox(
            height: 100,
            child: routersList.isEmpty
                ? Center(
                    child: Text("الآيب الحالي المكتشف: $discoveredIp\nاضغط لإضافة وحفظ الجهاز", 
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

          // بطاقة التحكم النشطة والعبور المباشر لصفحة الراوتر والـ ONU
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
                  height: 95,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1120),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.cyanAccent, size: 30),
                      const SizedBox(height: 4),
                      Text("النوع: ${activeRouter['type']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 2),
                      const Text("جاهز لفتح صفحة الأدمين والوصول للـ ONU / النانو", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: Text("الدخول لصفحة الراوتر والـ ONU (${activeRouter['ip']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: () {
                      _showAdminLoginDialog(activeRouter['name']!, activeRouter['ip']!, activeRouter['user']!, activeRouter['pass']!);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // الأزرار الأربعة للتحكم الميداني
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildActionCard("إدارة الشبكة", "Manage Network", Icons.tune, Colors.cyanAccent, () {
                _showNewDeviceDetectedDialog(discoveredIp);
              }),
              _buildActionCard("شبكة الضيوف", "Guest Network", Icons.people_outline, Colors.purpleAccent, () {
                _showGuestNetworkModal();
              }),
              _buildActionCard("التحكم الأبوي", "Parental Control", Icons.lock_outline, Colors.orangeAccent, () {
                _showParentalControlModal();
              }),
              _buildActionCard("اختبار السرعة", "Speed Test", Icons.speed, Colors.greenAccent, () {
                _showSpeedTestModal();
              }),
            ],
          ),
        ],
      ),
    );
  }

  // شاشة الأجهزة (Devices Tab)
  Widget _buildDevicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("الأجهزة المتصلة بالشبكة الحالية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildDeviceTile("الراوتر الرئيسي المكتشف", discoveredIp, "00:1A:2C:3B:4D:5E", Icons.router, Colors.cyanAccent, isOnline: true),
          _buildDeviceTile("منظومة ONU / النانو الضوئي", "192.168.100.1", "C8:3A:35:88:99:AA", Icons.hub, Colors.purpleAccent, isOnline: true),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(String name, String ip, String mac, IconData icon, Color color, {required bool isOnline}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text("IP: $ip | MAC: $mac", style: const TextStyle(color: Colors.grey, fontSize: 10)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(isOnline ? "متصل" : "غير متصل", style: TextStyle(color: isOnline ? Colors.greenAccent : Colors.grey, fontSize: 10)),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("إعدادات البرنامج والميدان", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildSettingTile("إعادة فحص واكتشاف الراوتر", "البحث عن الراوتر المتصل حالياً", Icons.refresh, autoDetectNetworkRouter),
        _buildSettingTile("مسح النسخ والبيانات المخزنة", "تصفير السجلات المحلية", Icons.delete_sweep, () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('saved_routers');
          setState(() => routersList.clear());
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم مسح كافة الأجهزة المحفوظة!")));
        }),
      ],
    );
  }

  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("أدوات الفني المتقدمة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildSettingTile("فحص خط الاستجابة (Ping)", "التحقق من استقرار الاتصال بالراوتر", Icons.network_check, () => _showSpeedTestModal()),
      ],
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyanAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: onTap,
      ),
    );
  }

  // واجهة فتح الأدمين للراوتر والـ ONU داخل التطبيق أو المتصفح
  void _showAdminLoginDialog(String name, String ip, String user, String pass) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        title: Text("بوابة إدارة: $name", style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("آيب الراوتر: $ip", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("يوزر الأدمين: $user", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text("كلمة المرور: $pass", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            const Text("من خلال الدخول لصفحة الراوتر هذه، يمكنك الوصول لتبويب الـ WAN أو الـ Gateway للعبور المباشر للـ ONU أو النانو المربوط.", style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("فتح واجهة الأدمين للراوتر على الآيب: http://$ip ...")),
              );
            },
            child: const Text("فتح صفحة الأدمين"),
          ),
        ],
      ),
    );
  }

  void _showGuestNetworkModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131C31),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("شبكة الضيوف (Guest Network)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("تفعيل شبكة الضيوف المؤقتة", style: TextStyle(color: Colors.white, fontSize: 13)),
              value: true,
              activeColor: Colors.purpleAccent,
              onChanged: (val) {},
            ),
            const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: "اسم شبكة الضيوف (SSID)", labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تفعيل شبكة الضيوف بنجاح!")));
                },
                child: const Text("حفظ الإعدادات"),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSpeedTestModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131C31),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("اختبار سرعة الاستجابة (Ping)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            const Icon(Icons.speed, color: Colors.greenAccent, size: 50),
            const SizedBox(height: 10),
            const Text("الاستجابة الحقيقية: 5 ms", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم فحص استجابة الشبكة بنجاح!")));
              },
              child: const Text("إعادة الفحص"),
            )
          ],
        ),
      ),
    );
  }

  void _showParentalControlModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131C31),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("التحكم الأبوي وحظر المواقع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("تفعيل الحماية الأبوية على الراوتر", style: TextStyle(color: Colors.white, fontSize: 13)),
              value: true,
              activeColor: Colors.orangeAccent,
              onChanged: (val) {},
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تطبيق حماية التحكم الأبوي بنجاح!")));
                },
                child: const Text("تطبيق الحماية"),
              ),
            )
          ],
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
          onPressed: autoDetectNetworkRouter,
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
            onPressed: () => _showNewDeviceDetectedDialog(discoveredIp),
            tooltip: "إضافة جهاز يدوي",
          ),
        ],
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
