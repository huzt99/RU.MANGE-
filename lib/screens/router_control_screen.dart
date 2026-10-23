// شاشة التحكم بالراوتر وتغيير الرمز وإدارة الإشارة
import 'package:flutter/material.dart';

class RouterControlScreen extends StatefulWidget {
  final String subscriberName;
  final String routerType;
  final String routerIp;

  RouterControlScreen({
    required this.subscriberName,
    required this.routerType,
    required this.routerIp,
  });

  @override
  _RouterControlScreenState createState() => _RouterControlScreenState();
}

class _RouterControlScreenState extends State<RouterControlScreen> {
  final _ssidController = TextEditingController(text: "MyHomeNet");
  final _passwordController = TextEditingController(text: "12345678");
  bool _isLoading = false;

  void _saveWifiSettings() async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(seconds: 1)); // محاكاة الحفظ
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم تغيير رمز الواي فاي واسم الشبكة بنجاح!")),
    );
  }

  void _rebootRouter() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("إعادة تشغيل الجهاز"),
        content: Text("هل أنت تأكد من إرسال أمر إعادة التشغيل للراوتر؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("جارٍ إعادة تشغيل الراوتر الآن...")),
              );
            },
            child: Text("إعادة التشغيل", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subscriberName),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة المعلومات القادمة من الجهاز
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("نوع الجهاز: ${widget.routerType}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 6),
                    Text("عنوان الـ IP: ${widget.routerIp}", style: TextStyle(color: Colors.grey[700])),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.green, size: 14),
                        SizedBox(width: 6),
                        Text("الإشارة الضوئية: -19.5 dBm (ممتازة)", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // إعدادات الواي فاي
            Text("تغيير إعدادات الواي فاي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: "اسم شبكة الواي فاي (SSID)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "رمز الواي فاي الجديد (Password)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _saveWifiSettings,
                icon: Icon(Icons.save, color: Colors.white),
                label: Text("حفظ التغييرات", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 30),

            // خيارات الصيانة والتحكم
            Text("إجراءات الصيانة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _rebootRouter,
              icon: Icon(Icons.restart_alt),
              label: Text("إعادة تشغيل الجهاز (Reboot)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
