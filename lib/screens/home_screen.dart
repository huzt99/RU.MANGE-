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
  List<String> routers = [];
  bool isScanning = true;
  String discoveredIp = "192.168.1.1";

  @override
  void initState() {
    super.initState();
    loadRouters();
    scanNetwork();
  }

  Future<void> loadRouters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      routers = prefs.getStringList('saved_routers') ?? [
        "Living Room (AC1900)|192.168.1.1|Cudy",
        "Bedroom (AX1800)|192.168.1.2|Huawei ONT",
        "Office (PritzBox)|192.168.1.3|ZTE ONU"
      ];
    });
  }

  Future<void> scanNetwork() async {
    setState(() => isScanning = true);
    String ip = await NetworkService.discoverRouterIP();
    setState(() {
      isScanning = false;
      discoveredIp = ip;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // خلفية داكنة فخمة نفس الصورة
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: const [
                Text("RouterHub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("راوترهب", style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Icon(Icons.security, color: Colors.cyanAccent, size: 28),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان الفرعي: الراوترات المتصلة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("الراوترات المتصلة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text("All Routers Connected", style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),

            // قائمة أفقية للراوترات (Living Room, Bedroom, Office)
            SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: routers.length,
                itemBuilder: (context, index) {
                  final parts = routers[index].split('|');
                  String name = parts.isNotEmpty ? parts[0] : "Router";
                  bool isSelected = index == 0;

                  return Container(
                    width: 115,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF131C31),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.cyanAccent : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.router, color: Colors.cyanAccent, size: 24),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text("متصل", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // بطاقة حالة الشبكة الشاملة (Overall Network Health)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131C31),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("حالة الشبكة: قوية", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("Overall Network Health: Strong", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // رسم توضيحي شبكي للراطور والـ ONU والأجهزة
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1120),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.hub, color: Colors.cyanAccent.withOpacity(0.4), size: 70),
                        Positioned(
                          bottom: 10,
                          child: Row(
                            children: const [
                              Icon(Icons.computer, color: Colors.blueAccent, size: 18),
                              SizedBox(width: 15),
                              Icon(Icons.wifi_tethering, color: Colors.greenAccent, size: 22),
                              SizedBox(width: 15),
                              Icon(Icons.phone_android, color: Colors.cyanAccent, size: 18),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          child: Text("الآيب النشط: $discoveredIp", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // أزرار التحكم الميداني الأربعة (إدارة الشبكة، شبكة الضيوف، التحكم الأبوي، اختبار السرعة)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics( ),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildActionCard("إدارة الشبكة", "Manage Network", Icons.tune, Colors.cyanAccent, () {
                  // فتح إعدادات الأدمين للراوتر والـ ONU
                }),
                _buildActionCard("شبكة الضيوف", "Guest Network", Icons.people_outline, Colors.purpleAccent, () {}),
                _buildActionCard("التحكم الأبوي", "Parental Control", Icons.lock_outline, Colors.orangeAccent, () {}),
                _buildActionCard("اختبار السرعة", "Speed Test", Icons.speed, Colors.greenAccent, () {
                  scanNetwork();
                }),
              ],
            ),
          ],
        ),
      ),
      // شريط التنقل السفلي الاحترافي
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
