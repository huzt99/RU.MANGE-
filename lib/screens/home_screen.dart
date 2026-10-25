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
  bool isScanningNetwork = true;
  String detectedGateway = "192.168.1.1";
  String networkStatusText = "جاري رصد بوابة الشبكة (Gateway) للراوتر أو الـ ONU...";

  @override
  void initState() {
    super.initState();
    loadRouters();
    autoDiscoverGatewayAndRouters();
  }

  Future<void> loadRouters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      routers = prefs.getStringList('saved_routers') ?? [];
    });
  }

  Future<void> autoDiscoverGatewayAndRouters() async {
    setState(() {
      isScanningNetwork = true;
      networkStatusText = "جاري مسح فضاء الشبكة ورصد الـ Gateway النشط...";
    });

    List<String> candidateGateways = [
      "192.168.1.1",
      "192.168.0.1",
      "192.168.8.1",
      "192.168.100.1",
      "192.168.101.1",
      "10.0.0.1",
      "172.16.0.1",
      "11.11.1.1",
      "80.80.80.8",
    ];

    String foundActiveIp = "";

    for (String ip in candidateGateways) {
      final result = await NetworkService.realPing(ip);
      if (result["status"] == true) {
        foundActiveIp = ip;
        break;
      }
    }

    setState(() {
      isScanningNetwork = false;
      if (foundActiveIp.isNotEmpty) {
        detectedGateway = foundActiveIp;
        networkStatusText = "تم رصد راوتر / ONU الميدان بنجاح على الآيب: $detectedGateway";
      } else {
        networkStatusText = "الشبكة متصلة، لكن لم يتم الاستجابة للبوابات الافتراضية. يمكنك إدخال الآيب يدوياً.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RU-Mange | الرادار الذكي لشبكات الميدان", textAlign: TextAlign.right),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.radar),
            onPressed: autoDiscoverGatewayAndRouters,
            tooltip: "إعادة الكشف التلقائي للـ Gateway",
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    const Text("رادار الـ Gateway التلقائي:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 15)),
                    const Spacer(),
                    if (!isScanningNetwork)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                        child: const Text("متصل", style: TextStyle(color: Colors.white, fontSize: 11)),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                isScanningNetwork
                    ? const Row(
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text("جاري فحص بوابات الشبكة والـ ONU...", style: TextStyle(fontSize: 13)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(networkStatusText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text("حفظ المكتشف", style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              showAddOrManageRouterDialog(context, detectedGateway, () {
                                loadRouters();
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
            child: Text("قائمة المشتركين والراوترات المحفوظة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),

          Expanded(
            child: routers.isEmpty
                ? const Center(
                    child: Text(
                      "لا توجد راوترات محفوظة حتى الآن.\nاضغط على زر (+) بالأسفل أو 'حفظ المكتشف' بالأعلى.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: routers.length,
                    itemBuilder: (context, index) {
                      final parts = routers[index].split('|');
                      final name = parts.isNotEmpty ? parts[0] : "مشترك";
                      final ip = parts.length > 1 ? parts[1] : "0.0.0.0";
                      final type = parts.length > 2 ? parts[2] : "راوتر / ONU";

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.wifi_tethering, color: Colors.purple, size: 28),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("الآيب (Gateway): $ip\nالنوع: $type"),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.network_check, color: Colors.green),
                                tooltip: "فحص الاتصال الميداني",
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 20),
                                          Text("جاري فحص خط الاستجابة..."),
                                        ],
                                      ),
                                    ),
                                  );

                                  final result = await NetworkService.realPing(ip);
                                  Navigator.pop(context);

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("تقرير الفحص الميداني"),
                                      content: Text("${result["message"]}\nالاستجابة: ${result["latency"]}"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("حسناً"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                                tooltip: "الدخول التلقائي لإدارة الراوتر",
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("إدارة جهاز: $name"),
                                      content: Text("البرنامج جاهز لحقن بيانات الدخول التلقائية والتحكم بـ ($ip).\nهل تريد فتح صفحة الإدارة؟"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("جاري الاتصال التلقائي بالراوتر عبر الآيب: $ip ...")),
                                            );
                                          },
                                          child: const Text("دخول تلقائي (Admin)"),
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
          showAddOrManageRouterDialog(context, detectedGateway, () {
            loadRouters();
          });
        },
      ),
    );
  }
}

void showAddOrManageRouterDialog(BuildContext context, String defaultIp, VoidCallback onRouterAdded) {
  final nameController = TextEditingController(text: "مشترك ميداني جديد");
  final ipController = TextEditingController(text: defaultIp);
  String selectedRouterType = 'Huawei ONT';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("حفظ وتجهيز آيب الراوتر / ONU", textAlign: TextAlign.right),
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
              decoration: const InputDecoration(
                labelText: "الـ Gateway (مثال: 192.168.1.1 أو 11.11.1.1)", 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRouterType,
              items: ['Huawei ONT', 'ZTE ONU', 'TP-Link Router', 'MikroTik', 'Ubiquiti Nano/Beam', 'آيب مخصص / Static', 'غير ذلك']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => selectedRouterType = value!,
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
            List<String> routers = prefs.getStringList('saved_routers') ?? [];
            routers.add("${nameController.text}|${ipController.text}|$selectedRouterType");
            await prefs.setStringList('saved_routers', routers);
            Navigator.pop(context);
            onRouterAdded();
          },
          child: const Text("حفظ في السجل"),
        ),
      ],
    ),
  );
}
