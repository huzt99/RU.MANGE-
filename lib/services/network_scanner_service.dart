// هذا الملف مسؤول عن جلب عنوان الـ IP للراوتر الذي تتصل به حالياً
import 'package:network_info_plus/network_info_plus.dart';

class NetworkScannerService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// جلب عنوان الراوتر (Gateway IP) للشبكة المتصل بها حالياً
  Future<String?> getConnectedRouterGateway() async {
    try {
      // جلب الـ IP الخاص بجهازك على الشبكة الحالية
      String? wifiIp = await _networkInfo.getWifiIP();
      
      if (wifiIp != null && wifiIp.isNotEmpty) {
        // استبدال الجزء الأخير بـ .1 للحصول على عنوان الراوتر الافتراضي
        List<String> parts = wifiIp.split('.');
        if (parts.length == 4) {
          String gateway = "${parts[0]}.${parts[1]}.${parts[2]}.1";
          return gateway;
        }
      }
      
      return "192.168.1.1"; // العنوان الافتراضي في حال التعذر
    } catch (e) {
      return "192.168.1.1";
    }
  }
}
