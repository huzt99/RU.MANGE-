import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  // دالة لجلب الآيب الحقيقي للـ Gateway للشبكة المتصل بها الهاتف حالياً
  static Future<String> getConnectedRouterIP() async {
    try {
      final info = NetworkInfo();
      String? gateway = await info.getWifiGatewayIP();
      if (gateway != null && gateway.isNotEmpty && gateway != "0.0.0.0") {
        return gateway;
      }
    } catch (e) {
      // في حال عدم توفر القراءة المباشرة
    }
    return "192.168.1.1"; // القيمة الافتراضية للتجربة الميدانية
  }

  // فحص نوع الراوتر بناءً على الاستجابة أو النطاق
  static String detectRouterBrand(String ip) {
    if (ip.contains("100.1") || ip.contains("100.2")) {
      return "منظومة ضوئية (ONU / ONT)";
    } else if (ip.startsWith("192.168.0") || ip.startsWith("192.168.1")) {
      return "TP-Link / Cudy / Tenda";
    } else if (ip.startsWith("192.168.8")) {
      return "راوتر محمول / 4G";
    }
    return "راوتر ميداني عام (Cudy / Tenda / TP-Link)";
  }
}
