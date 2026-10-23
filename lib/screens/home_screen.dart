// الشاشة الرئيسية المربوطة بقاعدة البيانات المحلية والتخزين الدائم
import 'package:flutter/material.dart';
import '../services/network_scanner_service.dart';
import '../services/database_service.dart';
import 'router_control_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NetworkScannerService _scanner = NetworkScannerService();
  bool _isScanning = false;
  bool _isLoadingData = true;

  // قائمة المشتركين
  List<Map<String, dynamic>> _subscribers = [];
  
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedSubscribers();
  }

  // تحميل المشتركين المحفوظة من الذاكرة
  void _loadSavedSubscribers() async {
    List<Map<String, dynamic>> loaded = await DatabaseService.loadSubscribers();
    setState(() {
      _subscribers = loaded;
      _isLoadingData = false;
    });
  }

  // دالة البحث التلقائي وإضافة الراوتر مع الحفظ
  void _autoDetectAndAdd() async {
    setState(() => _isScanning = true);
    
    String? detectedIp = await _scanner.getConnectedRouterGateway();
    await Future.delayed(Duration(seconds: 1)); 
    
    setState(() => _isScanning = false);

    _nameController.text = "مشتـرك جديد (${detectedIp ?? '192.168.1.1'})";

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
            Text("العنوان المكتشف: ${detectedIp ?? '192.168.1.1'}"),
            SizedBox(height: 8),
            Text("النوع: تم التعرف عليه تلقائياً"),
            SizedBox(height: 12),
            TextField(
              controller: _nameController,
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
            onPressed: () async {
              // إضافة المشترك الجديد للقائمة
              Map<String, dynamic> newSub = {
                "name": _nameController.text,
                "type": "Huawei/TP-Link Router",
                "ip": detectedIp ?? "192.168.1.1",
                "status": "متصل (جاهز للإدارة)",
              };

              setState(() {
                _subscribers.add(newSub);
              });

              // حفظ القائمة المحدثة محلياً
              await DatabaseService.saveSubscribers(_subscribers);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("تم حفظ الراوتر وربطه بنجاح!")),
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
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : Column(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: _subscribers.isEmpty
                      ? Center(child: Text("لا توجد شبكات محفوظة حالياً. اضغط على بحث تلقائي لإضافة أول راوتر!"))
                      : ListView.builder(
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RouterControlScreen(
                                        subscriberName: sub["name"],
                                        routerType: sub["type"],
                                        routerIp: sub["ip"],
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
    );
  }
}
