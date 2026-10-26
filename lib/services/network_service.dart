import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  // جلب الآيب الحقيقي للـ Gateway المتصل به الهاتف
  static Future<String> getConnectedRouterIP() async {
    try {
      final info = NetworkInfo();
      String? gateway = await info.getWifiGatewayIP();
      if (gateway != null && gateway.isNotEmpty && gateway != "0.0.0.0") {
        return gateway;
      }
    } catch (e) {
      // خطأ في جلب الآيب
    }
    return "192.168.1.1";
  }

  // فحص حالة الإنترنت واستجابة الخط (Ping Test حقيقي للاتصال)
  static Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // الإنترنت شغال ومتصل بالشبكة بنجاح
      }
    } catch (e) {
      return false; // لا يوجد اتصال بالإنترنت (فقط شبكة محلية)
    }
    return false;
  }

  // التعرف على نوع الراوتر بناءً على الآيب
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
