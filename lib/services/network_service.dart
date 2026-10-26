import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  // الرابط المباشر لحسابك على JSONBin السحابي
  static const String jsonBinUrl = 'https://api.jsonbin.io/v3/b/6ada49aaac6210605a49b2cb';
  static const String apiKey = r'$2a$10$4Tc0iksgy9.hUeH4n5LeCewNlWf46yUlr5vu5DfgU3KVbieJF5OvK';

  // جلب الآيب الحقيقي للـ Gateway المتصل به الهاتف
  static Future<String> getConnectedRouterIP() async {
    try {
      final info = NetworkInfo();
      String? gateway = await info.getWifiGatewayIP();
      if (gateway != null && gateway.isNotEmpty && gateway != "0.0.0.0") {
        return gateway;
      }
    } catch (e) {
      // التعامل مع الخطأ
    }
    return "192.168.1.1";
  }

  // فحص حالة الإنترنت
  static Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // التعرف التلقائي على نوع الراوتر أو المنظومة
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

  // رفع وحفظ بيانات الراوتر إلى حسابك السحابي
  static Future<bool> saveRouterToCloud(Map<String, String> routerData) async {
    try {
      final response = await http.put(
        Uri.parse(jsonBinUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': apiKey,
        },
        body: jsonEncode(routerData),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // سحب وجلب البيانات من السحابة للتحكم عن بعد من أي مكان
  static Future<Map<String, dynamic>?> fetchRouterFromCloud() async {
    try {
      final response = await http.get(
        Uri.parse(jsonBinUrl),
        headers: {
          'X-Master-Key': apiKey,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['record'] ?? {};
      }
    } catch (e) {
      // التعامل مع الخطأ
    }
    return null;
  }
}
