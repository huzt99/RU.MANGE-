// الشاشة الرئيسية لإدارة الشبكات والتسجيل المحلي //
import 'package:flutter/material.dart';
import 'package:ru_mange/services/network_scanner_service.dart';
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

  // القائمة المشتركين //
  List<Map<String, dynamic>> _subscribers = [];

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تأخير آمن لمنع أي انهيار لحظة الإقلاع ولحين اكتمال بناء الشاشة بالكامل //
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadSavedSubscribers();
      }
    });
  }

  // تحميل المشتركين المحفوظة من الذاكرة مع حماية ضد الخطأ //
  void _loadSavedSubscribers() async {
    try {
      final result = await DatabaseService.loadSubscribers();
      if (mounted) {
        setState(() {
          _subscribers = result ?? []; // حماية تامة ضد الـ null لمنع الانهيار
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subscribers = [];
          _isLoadingData = false;
        });
      }
    }
  }

  // دالة البحث والتعرف الآلي على شبكة الواي فاي //
  void _autoDetectAndAdd() async {
    setState(() => _isScanning = true);

    String? detectedIp = await _scanner.getConnectedRouterGateway();
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isScanning = false);

    _nameController.text = "مشترك جديد (${detectedIp ?? '192.168.1.1'})";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.router, color: Colors.blueAccent),
            const SizedBox(width: 10),
            const Text("تم اكتشاف راوتر جديد"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("العنوان المكتشف: ${detectedIp ?? '192.168.1.1'}"),
            const SizedBox(height: 6),
            const Text("النوع: تم التعرف عليه تلقائياً"),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم المشترك أو ملاحظة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Map<String, dynamic> newSub = {
                "name": _nameController.text,
                "type": "Huawei/TP-Link Router",
                "ip": detectedIp ?? "192.168.1.1",
                "status": "متصل (جاهز للعمل)",
              };

              setState(() {
                _subscribers.add(newSub);
              });

              await DatabaseService.saveSubscribers(_subscribers);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ الراوتر بنجاح')),
              );
            },
            child: const Text('حفظ الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'إدارة شبكات المشتركين',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // بطاقة الفحص والبحث التلقائي //
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
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
                          const Text("أهلاً بك، أيها الفني 🛠️", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 5),
                          Text("الشبكات المحفوظة: ${_subscribers.length}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                // قائمة المشتركين //
                Expanded(
                  child: _subscribers.isEmpty
                      ? const Center(child: Text('لا توجد شبكات محفوظة حالياً. اضغط على بحث تلقائي لإضافة أول راوتر'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _subscribers.length,
                          itemBuilder: (context, index) {
                            final sub = _subscribers[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  child: const Icon(Icons.router, color: Colors.blueAccent),
                                ),
                                title: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("${sub['type']} • ${sub['ip']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(sub['status'], style: const TextStyle(color: Colors.green, fontSize: 12)),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RouterControlScreen(
                                        subscriberName: sub['name'],
                                        routerType: sub['type'],
                                        routerIp: sub['ip'],
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "scanBtn",
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        onPressed: _isScanning ? null : _autoDetectAndAdd,
        label: _isScanning
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('بحث تلقائي', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: _isScanning ? null : const Icon(Icons.wifi_find),
      ),
    );
  }
}
