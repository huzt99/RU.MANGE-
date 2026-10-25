import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ru_mange/services/network_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> routers = [];
  bool isScanning = true;
  String discoveredRouterIp = "جاري رصد آيب الراوتر المربوط...";
  String networkStatusMsg = "جاري فحص شبكة الميدان لاكتشاف الراوتر و ONU...";

  @override
  void initState() {
    super.initState();
    loadSavedRouters();
    scanLocalRouter(); // بدء الاكتشاف التلقائي لآيب الراوتر عند الفتح
  }

  Future<void> loadSavedRouters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      routers = prefs.getStringList('saved_routers') ?? [];
    });
  }

  // دالة اكتشاف آيب الراوتر الحقيقي في شبكة الميدان
  Future<void> scanLocalRouter() async {
    setState(() {
      isScanning = true;
      networkStatusMsg = "جاري مسح الشبكة المحلية لاكتشاف الراوتر...";
    });

    String foundIp = await NetworkService.discoverRouterIP();

    setState(() {
      isScanning = false;
      discoveredRouterIp = foundIp;
      networkStatusMsg = "تم رصد آيب الراوتر بنجاح: $discoveredRouterIp";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RU-Mange | رادار آيب الراوتر والميدان", textAlign: TextAlign.right),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: scanLocalRouter,
            tooltip: "إعادة مسح واكتشاف الراوتر",
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط رادار اكتشاف آيب الراوتر الحقيقي
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade300, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.router, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text("راوتر الميدان المكتشف تلقائياً:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 15)),
                    const Spacer(),
                    if (!isScanning)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                        child: const Text("جاهز للدخول", style: TextStyle(color: Colors.white, fontSize: 11)),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                isScanning
                    ? const Row(
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text("جاري فحص نطاقات الشبكة والـ IP...", style: TextStyle(fontSize: 13)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(networkStatusMsg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text("الآيب الأساسي: $discoveredRouterIp", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.login, size: 16),
                            label: const Text("حفظ ودخول", style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              showAddRouterDialog(context, discoveredRouterIp, () {
                                loadSavedRouters();
                              });
                            },
                          )
                        ],
                      ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text("الراوترات والأجهزة المحفوظة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),

          // قائمة الأجهزة المحفوظة
          Expanded(
            child: routers.isEmpty
                ? const Center(
                    child: Text(
                      "لا توجد أجهزة محفوظة.\nاضغط على 'حفظ ودخول' بالأعلى لحفظ آيب الراوتر المكتشف.",
                      textAlign: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: routers.length,
                    itemBuilder: (context, index) {
                      final parts = routers[index].split('|');
                      final name = parts.isNotEmpty ? parts[0] : "راوتر المشترك";
                      final ip = parts.length > 1 ? parts[1] : "0.0.0.0";
                      final type = parts.length > 2 ? parts[2] : "راوتر / ONU";

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.wifi_tethering, color: Colors.purple, size: 28),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("آيب الراوتر: $ip\nالنوع: $type (موصول مع ONU/نانو)"),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.network_check, color: Colors.green),
                                tooltip: "فحص الاتصال",
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 20),
                                          Text("جاري فحص استجابة الراوتر..."),
                                        ],
                                      ),
                                    ),
                                  );

                                  final res = await NetworkService.realPing(ip);
                                  Navigator.pop(context);

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("تقرير فحص الميدان"),
                                      content: Text("${res["message"]}\nالاستجابة: ${res["latency"]}"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً")),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                                tooltip: "الدخول لإدارة الراوتر والـ ONU",
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("إدارة جهاز: $name"),
                                      content: Text("جاري تجهيز الدخول إلى آيب الراوتر ($ip).\nومن خلاله يمكنك الوصول للـ ONU أو النانو المرتبط."),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("فتح صفحة الأدمين للـ IP: $ip ...")),
                                            );
                                          },
                                          child: const Text("فتح صفحة الإدارة (Admin)"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          showAddRouterDialog(context, discoveredRouterIp, () {
            loadSavedRouters();
          });
        },
      ),
    );
  }
}

void showAddRouterDialog(BuildContext context, String defaultIp, VoidCallback onAdded) {
  final nameController = TextEditingController(text: "راوتر المكتب / المشترك");
  final ipController = TextEditingController(text: defaultIp);
  String selectedType = 'Cudy / راوتر رئيسي';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("حفظ آيب الراوتر والوصول للـ ONU", textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: "اسم المشترك أو الموقع", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: "آيب الراوتر المكتشف", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: ['Cudy / راوتر رئيسي', 'Huawei ONT', 'ZTE ONU', 'TP-Link Router', 'MikroTik', 'Ubiquiti Nano/Beam', 'آيب مخصص / Static', 'غير ذلك']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.isEmpty || ipController.text.isEmpty) return;
              final prefs = await SharedPreferences.getInstance();
              List<String> list = prefs.getStringList('saved_routers') ?? [];
              list.add("${nameController.text}|${ipController.text}|$selectedType");
              await prefs.setStringList('saved_routers', list);
              Navigator.pop(context);
              onAdded();
            },
            child: const Text("حفظ السجل"),
          ),
        ],
      ),
    ),
  );
}
