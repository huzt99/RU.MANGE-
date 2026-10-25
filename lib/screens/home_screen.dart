import 'package:flutter/material.dart';
import 'package:ru_mange/services/database_service.dart';
import 'package:ru_mange/screens/router_control_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> subscribers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscribersData();
  }

  // تحميل قائمة المشتركين المخزنة //
  Future<void> _loadSubscribersData() async {
    setState(() => isLoading = true);
    final data = await DatabaseService.loadSubscribers();
    setState(() {
      subscribers = data;
      isLoading = false;
    });
  }

  // نافذة إضافة مشترك جديد تلقائياً للميدان //
  void _showAddSubscriberDialog() {
    final nameController = TextEditingController();
    final ipController = TextEditingController(text: "192.168.1.1");
    String selectedType = "Huawei ONT";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حفظ راوتر المشترك جديد", textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: "اسم المشترك (مثال: علي - حي المعلمين)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "عنوان IP الراوتر",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "نوع الجهاز",
                  border: OutlineInputBorder(),
                ),
                items: ["Huawei ONT", "TP-Link Archer", "MikroTik", "Ubiquiti PowerBeam", "غير ذلك"]
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedType = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseService.addSubscriber(
                  name: "المشترك: ${nameController.text}",
                  type: selectedType,
                  ip: ipController.text,
                  status: "متصل (تم الحفظ حديثاً)",
                );
                Navigator.pop(context);
                _loadSubscribersData(); // تحديث القائمة
              }
            },
            child: const Text("حفظ المشترك"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('إدارة شبكات المشتركين', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscribersData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // كارت الترحيب والإحصائيات //
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.lightBlueAccent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "أهلاً بك، أيها الفني 🛠️",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "الشبكات المحفوظة: ${subscribers.length}",
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // قائمة المشتركين //
                  Expanded(
                    child: ListView.builder(
                      itemCount: subscribers.length,
                      itemBuilder: (context, index) {
                        final item = subscribers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.router, color: Colors.white),
                            ),
                            title: Text(
                              item['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("${item['type']} • ${item['ip']}", style: const TextStyle(color: Colors.grey)),
                                Text(
                                  item['status'] ?? '',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                            onTap: () {
                              // الانتقال للتحكم والتشخيص عن بُعد //
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RouterControlScreen(
                                    subscriberName: item['name'] ?? '',
                                    ipAddress: item['ip'] ?? '192.168.1.1',
                                    routerType: item['type'] ?? 'Huawei ONT',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      // زر الحفظ السريع / الكشف التلقائي //
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubscriberDialog,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("إضافة/حفظ راوتر", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
