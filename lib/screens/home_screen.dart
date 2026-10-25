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
  String detectedNetworkInfo = "جاري فحص الشبكة المتصل بها حالياً...";

  @override
  void initState() {
    super.initState();
    loadRouters();
    autoDetectCurrentNetwork(); // الاكتشاف التلقائي للشبكة عند فتح التطبيق مباشرة //
  }

  Future<void> loadRouters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      routers = prefs.getStringList('saved_routers') ?? [];
    });
  }

  // دالة الفحص التلقائي للشبكة الميدانية الحالية //
  Future<void> autoDetectCurrentNetwork() async {
    setState(() => isScanningNetwork = true);
    
    // محاولة فحص البوابة الافتراضية الشائعة للراوترات بالميدان (مثل شبكة المكتب أو راوتر المشترك)
    final pingResult = await NetworkService.realPing("192.168.1.1");
    
    setState(() {
      isScanningNetwork = false;
      if (pingResult["status"] == true) {
        detectedNetworkInfo = "تم اكتشاف راوتر متصل تلقائياً: 192.168.1.1 (استجابة: ${pingResult["latency"]})";
      } else {
        detectedNetworkInfo = "غير متصل براوتر محلي، يرجى التأكد من الاتصال بشبكة الواي فاي.";
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
            onPressed: autoDetectCurrentNetwork,
            tooltip: "إعادة فحص الشبكة الحالية",
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط الكشف التلقائي للشبكة الحالية (الميزة المطلوبة) //
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
                    Text("حالة شبكة الميدان الحالية:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                  ],
                ),
                const SizedBox(height: 6),
                isScanningNetwork
                    ? const Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text("جاري فحص الشبكة والـ Gateway..."),
                        ],
                      )
                    : Text(detectedNetworkInfo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("الراوترات والمشتركون المحفوظون:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 6),

          // قائمة المشترين والراوترات //
          Expanded(
            child: routers.isEmpty
                ? const Center(
                    child: Text(
                      "لا توجد راوترات محفوظة مسبقاً.\nاضغط على زر (+) بالأسفل لإضافة الراوتر المكتشف.",
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
                                      Text("جاري فحص اتصال الراوتر والخط..."),
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
          showAddRouterDialog(context, () {
            loadRouters();
          });
        },
      ),
    );
  }
}

void showAddRouterDialog(BuildContext context, VoidCallback onRouterAdded) {
  final nameController = TextEditingController(text: "راوتر المكتب / المشترك");
  final ipController = TextEditingController(text: "192.168.1.1");
  String selectedRouterType = 'Huawei ONT';
  bool autoConfigAdmin = true;

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
              SwitchListTile(
                title: const Text("تولّي البرنامج الفحص التلقائي", style: TextStyle(fontSize: 12)),
                value: autoConfigAdmin,
                onChanged: (val) => setState(() => autoConfigAdmin = val),
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
