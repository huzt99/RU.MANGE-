// هذا الملف يمثل الهيكل الأساسي الموحد لكل الراوترات والأونيوات (Drivers)
class OpticalInfo {
  final double rxPowerDbm; // قوة الإشارة الضوئية بالـ dBm (للـ ONT)
  
  OpticalInfo({required this.rxPowerDbm});

  String get statusMessage {
    if (rxPowerDbm >= -25.0) return "الإشارة الضوئية ممتازة";
    return "الإشارة الضوئية ضعيفة (يوجد انحناء أو كسر)";
  }
}

abstract class RouterDriver {
  final String ipAddress;
  final String username;
  final String password;

  RouterDriver({
    required this.ipAddress,
    required this.username,
    required this.password,
  });

  // تسجيل الدخول للراوتر
  Future<bool> login();

  // تغيير اسم شبكة الواي فاي والرمز
  Future<bool> changeWifiSettings({required String ssid, required String password});

  // إعادة تشغيل الراوتر (Reboot)
  Future<bool> reboot();
}
