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
  String detectedNetworkInfo = "جاري رصد شبكة المكتب والراوتر المتصل...";
  String activeGateway = "192.168.1.1";

  @override
  void initState() {
    super.initState();
    loadRouters();
    detectActiveGateway();
  }

  Future<void> loadRouters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      routers = prefs.getStringList('saved_routers') ?? [];
    });
  }

  // دالة البحث الذكي عن الـ Gateway النشط في شبكة المكتب/الميدان
  Future<void> detectActiveGateway() async {
    setState(() => isScanningNetwork = true);

    List<String> commonGateways = ["192.168.1.1", "192.168.0.1", "192.168.8.1", "10.0.0.1"];
    String foundIp = "";

    for (String gw in commonGateways) {
      final res = await NetworkService.realPing(gw);
      if (res["status"] == true) {
        foundIp = gw;
        break;
      }
    }

    setState(() {
      isScanningNetwork = false;
      if (foundIp.isNotEmpty) {
        activeGateway = foundIp;
        detectedNetworkInfo = "تم رصد الراوتر بنجاح على الـ IP: $activeGateway";
      } else {
        detectedNetworkInfo = "متصل بالشبكة المحلية، يرجى إدخال آيباد الراوتر يدوياً إذا لزم.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RU-Mange | رادار شبكات الميدان", textAlign: TextAlign.right),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: detectActiveGateway,
            tooltip: "إعادة رصد الشبكة",
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط رصد شبكة الميدان //
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.purple),
                    SizedBox(width: 8),
                    Text("حالة شبكة المكتب / الميدان الحالية:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                  ],
                ),
                const SizedBox(height: 6),
                isScanningNetwork
                    ? const Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text("جاري فحص بوابات الشبكة (Gateways)..."),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Expanded(
                            child: Text(detectedNetworkInfo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.add_to_photos, size: 16),
                            label: const Text("حفظ هذا الراوتر", style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              showAddRouterDialog(context, activeGateway, () {
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
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("الراوترات والمشتركون المحفوظون:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 6),

          // قائمة المشتركين //
          Expanded(
            child: routers.isEmpty
                ? const Center(
                    child: Text(
                      "لا توجد راوترات محفوظة مسبقاً.\nاضغط على زر (+) بالأسفل أو زر الحفظ بالأعلى.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: routers.length,
                    itemBuilder: (context, index) {
                      final parts = routers[index].split('|');
                      final name = parts.isNotEmpty ? parts[0] : "مشترك";
                      final ip = parts.length > 1 ? parts[1] : "0.0.0.0";
                      final type = parts.length > 2 ? parts[2] : "راوتر";

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.router, color: Colors.purple),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("IP: $ip | النوع: $type"),
                          trailing: IconButton(
                            icon: const Icon(Icons.network_check, color: Colors.green),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (context) => const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 20),
                                      Text("جاري فحص اتصال الراوتر..."),
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
          showAddRouterDialog(context, activeGateway, () {
            loadRouters();
          });
        },
      ),
    );
  }
}

void showAddRouterDialog(BuildContext context, String defaultIp, VoidCallback onRouterAdded) {
  final nameController = TextEditingController(text: "راوتر المكتب");
  final ipController = TextEditingController(text: defaultIp);
  String selectedRouterType = 'Huawei ONT';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("حفظ الراوتر المكتشف", textAlign: TextAlign.right),
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
                decoration: const InputDecoration(labelText: "الراوتر IP", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRouterType,
                items: ['Huawei ONT', 'TP-Link Archer', 'MikroTik', 'Ubiquiti PowerBeam', 'غير ذلك']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => selectedRouterType = value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final prefs = await SharedPreferences.getInstance();
              List<String> routers = prefs.getStringList('saved_routers') ?? [];
              routers.add("${nameController.text}|${ipController.text}|$selectedRouterType");
              await prefs.setStringList('saved_routers', routers);
              Navigator.pop(context);
              onRouterAdded();
            },
            child: const Text("حفظ السجل"),
          ),
        ],
      ),
    ),
  );
}
