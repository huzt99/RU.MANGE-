// هذه هي واجهة المستخدم الرئيسية التي تعرض المشتركين وزر البحث التلقائي
import 'package:flutter/material.dart';
import '../services/network_scanner_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NetworkScannerService _scanner = NetworkScannerService();
  bool _isScanning = false;

  // قائمة تجريبية للمشتركين
  final List<Map<String, dynamic>> _subscribers = [
    {
      "name": "المشترك: أحمد (حي الحسين)",
      "type": "Huawei ONT (ضوئي)",
      "ip": "192.168.1.1",
      "status": "ممتازة (-19.2 dBm)",
    },
    {
      "name": "المشترك: علي كريم (الرئيسية)",
      "type": "TP-Link Archer C80",
      "ip": "192.168.0.1",
      "status": "متصل (1Gbps)",
    },
  ];

  // دالة البحث التلقائي وإضافة الراوتر
  void _autoDetectAndAdd() async {
    setState(() => _isScanning = true);
    
    // جلب الـ IP الحالي للراوتر
    String? detectedIp = await _scanner.getConnectedRouterGateway();
    
    await Future.delayed(Duration(seconds: 1)); // محاكاة عملية الفحص السريع
    
    setState(() => _isScanning = false);

    // إظهار نافذة منبثقة لإضافة المشترك المكتشف
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.router, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("تم اكتشاف راوتر جديد!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("العنوان المكتشف: $detectedIp"),
            SizedBox(height: 8),
            Text("النوع: تم التعرف عليه تلقائياً"),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "اسم المشترك أو ملاحظة",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("تم حفظ الراوتر بنجاح!")),
              );
            },
            child: Text("حفظ وربط", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "إدارة شبكات المشتركين",
          style: TextStyle(color: Colors.black86, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // بطاقة الفحص والبحث التلقائي
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("أهلاً بك، أيها التقني 🛠️", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 5),
                    Text("الشبكات المحفوظة: ${_subscribers.length}", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                FloatingActionButton.extended(
                  heroTag: "scanBtn",
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  onPressed: _isScanning ? null : _autoDetectAndAdd,
                  label: _isScanning 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text("بحث تلقائي", style: TextStyle(fontWeight: FontWeight.bold)),
                  icon: _isScanning ? null : Icon(Icons.wifi_find),
                ),
              ],
            ),
          ),
          
          // قائمة المشتركين
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _subscribers.length,
              itemBuilder: (context, index) {
                final sub = _subscribers[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Icon(Icons.router, color: Colors.blueAccent),
                    ),
                    title: Text(sub["name"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text("${sub["type"]} • ${sub["ip"]}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        SizedBox(height: 4),
                        Text(sub["status"], style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
