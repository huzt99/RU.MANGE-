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

  @override
  void initState() {
    super.initState();
    loadRouters();
  }

  Future<void> loadRouters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      routers = prefs.getStringList('saved_routers') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RU-Mange | إدارة شبكات الميدان", textAlign: TextAlign.right),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: routers.isEmpty
          ? const Center(
              child: Text(
                "لا توجد راوترات محفوظة.\nاضغط على زر (+) لإضافة أول راوتر للمشترك.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("IP: $ip | النوع: $type"),
                    trailing: IconButton(
                      icon: const Icon(Icons.network_check, color: Colors.purple),
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
  final nameController = TextEditingController();
  final ipController = TextEditingController(text: "192.168.1.1");
  String selectedRouterType = 'Huawei ONT';
  bool autoConfigAdmin = true;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("إضافة وحفظ راوتر المشترك", textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: "اسم المشترك", border: OutlineInputBorder()),
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
            child: const Text("حفظ"),
          ),
        ],
      ),
    ),
  );
}
