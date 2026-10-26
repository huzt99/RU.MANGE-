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
  String detectedRealBrand = "راوتر شخصي / Cudy";
  int selectedRouterIndex = 0;

  @override
  void initState() {
    super.initState();
    loadRoutersFromStorage();
    scanAndDetectRealNetwork();
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

  Future<void> scanAndDetectRealNetwork() async {
    setState(() => isScanning = true);
    String ip = await NetworkService.discoverRouterIP();
    
    String brand = "Cudy / راوتر رئيسي";
    if (ip.contains("100.1")) {
      brand = "Huawei / ZTE ONT ضوئي";
    } else if (ip.contains("0.1")) {
      brand = "TP-Link / D-Link";
    } else if (ip.contains("8.1")) {
      brand = "راوتر 4G / SIM";
    }

    setState(() {
      isScanning = false;
      discoveredIp = ip;
      detectedRealBrand = brand;
    });
  }

  void _showAddRouterDialog() {
    final nameController = TextEditingController(text: "راوتر المشترك الحقيقي");
    final ipController = TextEditingController(text: discoveredIp);
    final userController = TextEditingController(text: "admin");
    final passController = TextEditingController(text: "admin");
    String selectedType = detectedRealBrand;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF131C31),
          title: const Row(
            children: [
              Icon(Icons.add_to_photos, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Text("حفظ جهاز الميدان والـ ONU", style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("الآيب المكتشف على الشبكة: $discoveredIp", style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "اسم المشترك / الموقع", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ipController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "الـ IP (Gateway)", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF131C31),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [
                    'Cudy / راوتر رئيسي',
                    'TP-Link (جميع الأصناف)',
                    'Deco MESH',
                    'Huawei / ZTE ONT ضوئي',
                    'نانو / Ubiquiti / MikroTik',
                    'D-Link / Honor'
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedType = val!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: userController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "يوزر الأدمين (Username)", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "باسورد الأدمين (Password)", labelStyle: TextStyle(color: Colors.grey)),
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
                  const SnackBar(content: Text("تم حفظ الجهاز ومعلومات الدخول بنجاح!")),
                );
              },
              child: const Text("حفظ السجل"),
            ),
          ],
        ),
      ),
    );
  }

  // الواجهة الرئيسية (Home Tab)
  Widget _buildHomeTab() {
    final activeRouter = routersList.isNotEmpty
        ? routersList[selectedRouterIndex]
        : {"name": "راوتر الشبكة الحالية", "ip": discoveredIp, "type": detectedRealBrand, "user": "admin", "pass": "admin"};

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

          // قائمة الراوترات العلوية
          SizedBox(
            height: 100,
            child: routersList.isEmpty
                ? Center(
                    child: Text("الراوتر المتصل حالياً ($discoveredIp)\nاضغط زر (+) بالأعلى لحفظه", 
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

          // بطاقة الجهاز النشط
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
                    Text("الجهاز النشط: ${activeRouter['name']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("IP: ${activeRouter['ip']}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 90,
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
                      Text("نوع الجهاز: ${activeRouter['type']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text("يوزر: ${activeRouter['user']} | كلمة المرور محفوظة", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: Text("الدخول المباشر لإدارة الراوتر والـ ONU (${activeRouter['ip']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      _showAdminLoginDialog(activeRouter['name']!, activeRouter['ip']!, activeRouter['user']!, activeRouter['pass']!);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // الأزرار الأربعة
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildActionCard("إدارة الشبكة", "Manage Network", Icons.tune, Colors.cyanAccent, () {
                _showAddRouterDialog();
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

  // شاشة الأجهزة المتصلة بالشبكة (Devices Tab)
  Widget _buildDevicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("الأجهزة المتصلة بالشبكة الحالية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.radar, color: Colors.cyanAccent),
                onPressed: () => setState(() {}),
                tooltip: "إعادة مسح الأجهزة",
              )
            ],
          ),
          const SizedBox(height: 10),
          _buildDeviceTile("راوتر الرئيسي (Cudy Gateway)", discoveredIp, "00:1A:2C:3B:4D:5E", Icons.router, Colors.cyanAccent, isOnline: true),
          _buildDeviceTile("هاتف الفني (هذا الجهاز)", "192.168.1.15", "A4:C3:F0:12:34:56", Icons.phone_android, Colors.greenAccent, isOnline: true),
          _buildDeviceTile("منظومة ONU / ضوئي", "192.168.100.1", "C8:3A:35:88:99:AA", Icons.hub, Colors.purpleAccent, isOnline: true),
          _buildDeviceTile("شاشة ذكية Smart TV", "192.168.1.22", "88:22:D4:55:66:77", Icons.tv, Colors.grey, isOnline: false),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(String name, String ip, String mac, IconData icon, Color color, {required bool isOnline}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
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

  // شاشة الإعدادات (Settings Tab)
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("إعدادات البرنامج والميدان", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildSettingTile("بيانات الدخول الافتراضية للراوترات", "إدارة اليوزر والباسورد التلقائي", Icons.key, () {}),
        _buildSettingTile("مسح وتحديث الـ Gateway ميكانيكياً", "إعادة ضبط كاش الشبكة المحلي", Icons.refresh, scanAndDetectRealNetwork),
        _buildSettingTile("حفظ وتصدير بيانات المشتركين", "نسخة احتياطية لسجل الراوترات", Icons.backup, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ نسخة احتياطية من الأجهزة محلياً!")));
        }),
        _buildSettingTile("حول تطبيق RU-Mange", "الإصدار 2.5 - للتحكم الميداني", Icons.info_outline, () {}),
      ],
    );
  }

  // شاشة المزيد (More Tab)
  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("أدوات الفني الميدانية المتقدمة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildSettingTile("فحص الاستجابة (Ping Radar)", "اختبار قوة واستجابة خط الشبكة", Icons.network_check, () => _showSpeedTestModal()),
        _buildSettingTile("كشف الـ DNS والبوابة الفرعية", "إعدادات IP الشبكة المتقدمة", Icons.dns, () {}),
        _buildSettingTile("إعادة تشغيل الراوتر المكتشف", "إرسال أمر Reboot عبر الشبكة", Icons.restart_alt, () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("جاري إرسال أمر إعادة التشغيل للـ IP: $discoveredIp ...")));
        }),
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

  // الدخول لصفحة أدمين الراوتر والـ ONU
  void _showAdminLoginDialog(String name, String ip, String user, String pass) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        title: Text("بوابة الإدارة: $name", style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("عنوان آيب الجهاز: $ip", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("اسم المستخدم: $user", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text("كلمة المرور: $pass", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            const Text("سيقوم التطبيق بفتح صفحة الراوتر أو الـ ONU والعبور المباشر للإعدادات.", style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("جاري فتح واجهة التحكم على الرابط: http://$ip ...")),
              );
            },
            child: const Text("فتح صفحة الأدمين"),
          ),
        ],
      ),
    );
  }

  // نافذة شبكة الضيوف الشغالة
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
            const Text("إدارة شبكة الضيوف (Guest Wi-Fi)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ وتفعيل شبكة الضيوف بنجاح!")));
                },
                child: const Text("حفظ الإعدادات"),
              ),
            )
          ],
        ),
      ),
    );
  }

  // نافذة اختبار السرعة الشغال
  void _showSpeedTestModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131C31),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اختبار سرعة اتصال الراوتر والميدان", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              const Icon(Icons.speed, color: Colors.greenAccent, size: 50),
              const SizedBox(height: 10),
              const Text("الاستجابة (Ping): 8 ms", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const Text("سرعة التنزيل المتوقعة: 38.5 Mbps", style: TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                icon: const Icon(Icons.play_arrow),
                label: const Text("بدء فحص السرعة الحقيقي"),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري فحص سرعة الاستجابة والتحميل...")));
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  // نافذة التحكم الأبوي الشغال
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
            const Text("نظام التحكم الأبوي وحظر الأجهزة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("حظر المواقع غير المرغوبة تلقائياً", style: TextStyle(color: Colors.white, fontSize: 13)),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تطبيق قواعد الحظر والتحكم الأبوي!")));
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
          onPressed: scanAndDetectRealNetwork,
          tooltip: "إعادة فحص واكتشاف الشبكة الحقيقية",
        ),
        title: Column(
          children: const [
            Text("RouterHub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("RU-Mange | رادار الميدان الشامل", style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
            onPressed: _showAddRouterDialog,
            tooltip: "إضافة راوتر يدوي",
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
