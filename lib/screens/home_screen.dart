import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// دالة إظهار نافذة إضافة الراوتر الذكية مع خيار الأدمينية //
void showAddRouterDialog(BuildContext context, VoidCallback onRouterAdded) {
  final nameController = TextEditingController();
  final ipController = TextEditingController(text: "192.168.1.1");
  final adminUserCtrl = TextEditingController(text: "admin");
  final adminPassCtrl = TextEditingController();
  
  String selectedRouterType = 'Huawei ONT';
  bool autoConfigAdmin = true; // الخيار الافتراضي: دع البرنامج يتكفل بذلك

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
                decoration: const InputDecoration(
                  labelText: "اسم المشترك (مثلاً: علي كاظم)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: "الراوتر IP (البوابة الافتراضية)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRouterType,
                alignment: Alignment.centerRight,
                decoration: const InputDecoration(
                  labelText: "نوع الجهاز / الراوتر",
                  border: OutlineInputBorder(),
                ),
                items: ['Huawei ONT', 'TP-Link Archer', 'MikroTik', 'Ubiquiti PowerBeam', 'غير ذلك']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type, textAlign: TextAlign.right),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedRouterType = value!),
              ),
              const SizedBox(height: 16),
              const Divider(),
              
              // اختيار طريقة الأدمينية (يدوي أو تلقائي عبر البرنامج) //
              const Text("إعدادات الدخول والأدمينية:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SwitchListTile(
                title: const Text("دع البرنامج يتكفل بالاتخاد التلقائي", style: TextStyle(fontSize: 12)),
                value: autoConfigAdmin,
                onChanged: (val) => setState(() => autoConfigAdmin = val),
              ),
              
              if (!autoConfigAdmin) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: adminUserCtrl,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "اسم المستخدم (Admin User)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: adminPassCtrl,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: "كلمة مرور الأدمين (Password)", border: OutlineInputBorder()),
                ),
              ],
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
              if (nameController.text.isEmpty) return;

              // حفظ البيانات محلياً عبر SharedPreferences //
              final prefs = await SharedPreferences.getInstance();
              List<String> routers = prefs.getStringList('saved_routers') ?? [];
              
              String routerData = "${nameController.text}|${ipController.text}|$selectedRouterType";
              routers.add(routerData);
              await prefs.setStringList('saved_routers', routers);

              Navigator.pop(context);
              onRouterAdded();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(autoConfigAdmin 
                      ? "🤖 تم حفظ الراوتر، وتولى البرنامج الكشف التلقائي للإشارة!" 
                      : "🔐 تم حفظ الراوتر مع بيانات الأدمينية اليدوية بنجاح!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("حفظ الراوتر"),
          ),
        ],
      ),
    ),
  );
}
