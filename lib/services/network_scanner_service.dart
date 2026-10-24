// خدمة جلب عنوان الـ IP للراوتر المتصل به حالياً - نسخة آمنة ضد الانهيار
import 'package:network_info_plus/network_info_plus.dart';

class NetworkScannerService {
  final NetworkInfo _networkInfo = NetworkInfo();

  // جلب عنوان الراوتر (Gateway IP) بشكل آمن تماماً
  Future<String> getConnectedRouterGateway() async {
    try {
      // محاولة الحصول على الـ IP مع حماية ضد غياب صلاحيات الموقع
      String? wifiIp = await _networkInfo.getWifiIP();

      if (wifiIp != null && wifiIp.isNotEmpty) {
        List<String> parts = wifiIp.split('.');
        if (parts.length == 4) {
          String gateway = "${parts[0]}.${parts[1]}.${parts[2]}.1";
          return gateway;
        }
      }
      
      return "192.168.1.1"; // القيمة الافتراضية الآمنة
    } catch (e) {
      // في حال حدوث أي خطأ أو نقص صلاحيات، نرجع العنوان الافتراضي ولا نترك التطبيق ينهار
      print("Network Info Error: $e");
      return "192.168.1.1";
    }
  }
}
