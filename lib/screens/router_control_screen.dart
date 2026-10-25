import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouterControlScreen extends StatefulWidget {
  final String subscriberName;
  final String ipAddress;
  final String routerType;

  const RouterControlScreen({
    super.key,
    required this.subscriberName,
    required this.ipAddress,
    required this.routerType,
  });

  @override
  State<RouterControlScreen> createState() => _RouterControlScreenState();
}

class _RouterControlScreenState extends State<RouterControlScreen> {
  bool isTestingPing = false;
  String pingResult = "لم يتم إجراء الفحص بعد";
  
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // تحميل ملاحظات الصيانة الخاصة بهذا المشترك //
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notesController.text = prefs.getString('notes_${widget.subscriberName}') ?? '';
    });
  }

  // حفظ ملاحظات الصيانة محلياً //
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes_${widget.subscriberName}', _notesController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ تم حفظ سجل الصيانة والملاحظات بنجاح!"), backgroundColor: Colors.green),
    );
  }

  // محاكاة فحص البينك وكشف الأخطاء وضعف الخدمة //
  void _runPingTest() async {
    setState(() {
      isTestingPing = true;
      pingResult = "جاري فحص الاستجابة (Ping to ${widget.ipAddress})...";
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isTestingPing = false;
      pingResult = "✅ الاستجابة ممتازة! البينك: 4ms | فقدان حزم البيانات: 0% (الخط سليم تماماً)";
    });
  }

  // نافذة الوصول المباشر لأجهزة الـ ONU (الضوئي) //
  void _openOnuLoginPortal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("الوصول السريع لجهاز ONU", textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "اختر إصدار الـ ONU المراد الدخول لإجهاده أو فحص الإشارة:",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.lan, color: Colors.blue),
              title: const Text("Huawei / ZTE ONU (192.168.1.1)", textAlign: TextAlign.right),
              onTap: () {
                Navigator.pop(context);
                _launchBrowser("http://192.168.1.1");
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
        ],
      ),
    );
  }

  // نافذة الوصول المباشر لأجهزة الأبراج والأثيرنت (Nano / PowerBeam / MikroTik) //
  void _openTowerDevicePortal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("الوصول المباشر لأجهزة الأبراج (إيرث لينك)", textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "اختر جهاز البث الخاص بالمشترك (البرج / النانو):",
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.router, color: Colors.amber),
                title: const Text("NanoStation M5 / LiteBeam (192.168.1.20)", textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  _launchBrowser("http://192.168.1.20");
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_input_antenna, color: Colors.deepOrange),
                title: const Text("PowerBeam M5 (الافتراضي 192.168.1.20)", textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  _launchBrowser("http://192.168.1.20");
                },
              ),
              ListTile(
                leading: const Icon(Icons.router_outlined, color: Colors.red),
                title: const Text("MikroTik Router / CPE (192.168.88.1)", textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  _launchBrowser("http://192.168.88.1");
                },
              ),
              ListTile(
                leading: const Icon(Icons.wifi, color: Colors.blueGrey),
                title: const Text("TP-Link Outdoor / CPE610", textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  _launchBrowser("http://192.168.0.254");
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
        ],
      ),
    );
  }

  void _launchBrowser(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🔗 جاري توجيه الاتصال إلى بوابة الجهاز عبر: $url"), backgroundColor: Colors.indigo),
    );
  }

  // محاكاة تغيير رمز الواي فاي //
  void _changeWiFiSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تغيير إعدادات الواي فاي", textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ssidController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: "اسم الشبكة الجديد (SSID)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: "كلمة المرور الجديدة", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم إرسال أمر تحديث الرمز إلى الراوتر بنجاح!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("حفظ وتطبيق"),
          ),
        ],
      ),
    );
  }

  // إعادة تشغيل الراوتر //
  void _rebootRouter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إعادة تشغيل الراوتر", textAlign: TextAlign.right),
        content: const Text("هل أنت متأكد من رغبتك في إرسال أمر إعادة التشغيل (Reboot) للراوتر عن بُعد؟", textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🔄 تم تنفيذ أمر إعادة التشغيل بنجاح!"), backgroundColor: Colors.red),
              );
            },
            child: const Text("إعادة تشغيل"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subscriberName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // بطاقة معلومات الراوتر والاتصال //
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.router, size: 40, color: Colors.purple),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(widget.subscriberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("${widget.routerType} • IP: ${widget.ipAddress}", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // زر الدخول المباشر لأجهزة الأونيو (FTTH) //
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openOnuLoginPortal,
                icon: const Icon(Icons.settings_ethernet),
                label: const Text("🌐 الدخول المباشر لجهاز ONU (الضوئي)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),

            // زر الدخول المباشر لأجهزة الأبراج والأثيرنت (Nano / PowerBeam / MikroTik) //
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openTowerDevicePortal,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text("📡 الدخول المباشر لنانو البرج (PowerBeam / MikroTik)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 20),

            // قسم التشخيص وكشف الأخطاء (Ping Test) //
            const Text("🔍 تشخيص الأخطاء وفحص الخط", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(pingResult, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      onPressed: isTestingPing ? null : _runPingTest,
                      icon: isTestingPing 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.network_ping),
                      label: Text(isTestingPing ? "جاري الفحص..." : "فحص البينك وكشف سبب الضعف"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // قسم سجل الصيانة والملاحظات الميدانية //
            const Text("📝 سجل صيانة المشترك وملاحظات الفني", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: "اكتب تفاصيل الصيانة هنا (مثلاً: تم تبديل الكابل، تغيير البورت، فحص الإشارة...)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                onPressed: _saveNotes,
                icon: const Icon(Icons.save),
                label: const Text("حفظ سجل الصيانة للمشترك"),
              ),
            ),
            const SizedBox(height: 25),

            // قسم التحكم السريع (تغيير الرمز وإعادة التشغيل) //
            const Text("⚡ أدوات التحكم السريع بالفني", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: _changeWiFiSettings,
                    icon: const Icon(Icons.wifi_password),
                    label: const Text("تغيير الرمز"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: _rebootRouter,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text("إعادة تشغيل"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
