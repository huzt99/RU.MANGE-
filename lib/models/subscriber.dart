// هذا الملف يحفظ معلومات المشترك والراوتر الخاص به
enum RouterType { tplink, tenda, huaweiOnt, xiaomi, generic }

class Subscriber {
  final String id;
  String name;             // اسم المشترك أو عنوانه
  String phone;            // رقم الهاتف
  String routerIp;         // مثال: 192.168.1.1
  String adminUsername;    // اسم المستخدم للراوتر (غالباً admin)
  String adminPassword;    // كلمة السر
  RouterType routerType;   // نوع الراوتر
  DateTime lastConnected;  // آخر اتصال

  Subscriber({
    required this.id,
    required this.name,
    required this.phone,
    required this.routerIp,
    required this.adminUsername,
    required this.adminPassword,
    required this.routerType,
    DateTime? lastConnected,
  }) : this.lastConnected = lastConnected ?? DateTime.now();
}
