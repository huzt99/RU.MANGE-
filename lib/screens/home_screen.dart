import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, String>> routersList = [];
  int selectedRouterIndex = 0;

  @override
  void initState() {
    super.initState();
    loadRoutersFromStorage();
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
            "type": parts.length > 2 ? parts[2] : "راوتر مع ONU / نانو",
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

  // نافذة إدخال آيب الراوتر الحقيقي يدوياً (الذي يتصل به الفني في الموقع)
  void _showAddRealRouterDialog() {
    final nameController = TextEditingController(text: "مشترك ميداني جديد");
    final ipController = TextEditingController(text: "192.168.10.1"); // الآيب الحقيقي الذي تدخله أنت
    final userController = TextEditingController(text: "admin");
    final passController = TextEditingController(text: "admin");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C31),
        title: const Text("إضافة راوتر الميدان والـ ONU", style: TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("أدخل آيب الراوتر الحقيقي المتصل به (مثال: 192.168.10.1)", style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.right),
              const SizedBox(height: 10),
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
                decoration: const InputDecoration(labelText: "آيب الراوتر الفعلي (Gateway)", labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: userController,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: "يوزر الدخول (Admin)", labelStyle: TextStyle(color: Colors.grey)),
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
              if (nameController.text.isEmpty || ipController.text.isEmpty) return;
              setState(() {
                routersList.add({
                  "name": nameController.text,
                  "ip": ipController.text,
                  "type": "راوتر رئيسي مع ONU / نانو",
                  "user": userController.text,
                  "pass": passController.text,
                });
                selectedRouterIndex = routersList.length - 1;
              });
              saveRoutersToStorage();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم حفظ الراوتر الحقيقي وظهوره في القائمة العلوية بنجاح!")),
              );
            },
            child: const Text("حفظ الجهاز"),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final activeRouter = routersList.isNotEmpty
        ? routersList[selectedRouterIndex]
        : {"name": "لا يوجد جهاز محفوظ", "ip": "192.168.10.1", "type": "اضغط (+) لإضافة جهاز", "user": "admin", "pass": "admin"};

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

          // القائمة العلوية الأفقية للأجهزة المحفوظة
          SizedBox(
            height: 100,
            child: routersList.isEmpty
                ? Center(
                    child: Text("لم تقم بحفظ أي جهاز بعد.\nاضغط على زر (+) بالأعلى لإضافة الراوتر الحقيقي.", 
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

          // بطاقة التحكم والعبور لمعرفة Gateway الـ ONU أو النانو
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
                      const Icon(Icons.hub, color: Colors.cyanAccent, size: 30),
                      const SizedBox(height: 4),
                      Text("الراوتر والـ Gateway (${activeRouter['ip']})", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      const Text("افتح الراوتر لمعرفة بوابة الربط مع الأوني/النانو", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                    icon: const Icon(Icons.login, size: 18),
                    label: Text("فتح صفحة الراوتر الحقيقي (${activeRouter['ip']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
              _buildActionCard("إدارة الشبكة", "Manage Network", Icons.tune, Colors.cyanAccent, _showAddRealRouterDialog),
              _buildActionCard("شبكة الضيوف", "Guest Network", Icons.people_outline, Colors.purpleAccent, () {}),
              _buildActionCard("التحكم الأبوي", "Parental Control", Icons.lock_outline, Colors.orangeAccent, () {}),
              _buildActionCard("اختبار السرعة", "Speed Test", Icons.speed, Colors.greenAccent, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    return const Center(child: Text("قائمة الأجهزة المتصلة", style: TextStyle(color: Colors.white)));
  }

  Widget _buildSettingsTab() {
    return const Center(child: Text("الإعدادات", style: TextStyle(color: Colors.white)));
  }

  Widget _buildMoreTab() {
    return const Center(child: Text("المزيد من الأدوات", style: TextStyle(color: Colors.white)));
  }

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
            Text("الآيب الحقيقي للراوتر: $ip", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("يوزر الدخول: $user", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text("كلمة المرور: $pass", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            const Text("من خلال فتح صفحة الراوتر عبر هذا الآيب، ستتمكن من رؤية الـ Gateway والوصول المباشر للـ ONU أو النانو.", style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("جاري فتح واجهة الراوتر على الآيب الحقيقي: http://$ip ...")),
              );
            },
            child: const Text("فتح صفحة الأدمين"),
          ),
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
            Text("RU-Mange | إدارة راوترات الميدان", style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
            onPressed: _showAddRealRouterDialog,
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
