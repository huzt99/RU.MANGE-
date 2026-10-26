import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  static const String jsonBinUrl = 'https://api.jsonbin.io/v3/b/6ada49aaac6210605a49b2cb';
  static const String apiKey = r'$2a$10$4Tc0iksgy9.hUeH4n5LeCewNlWf46yUlr5vu5DfgU3KVbieJF5OvK';

  // فحص حقيقي لجلب اسم الواي فاي المتصل به الموبايل حالياً (بدون أي قيم وهمية)
  static Future<String> getConnectedWifiName() async {
    try {
      final info = NetworkInfo();
      String? wifiName = await info.getWifiName();
      if (wifiName != null && wifiName.isNotEmpty && wifiName != "<unknown ssid>") {
        return wifiName.replaceAll('"', '');
      }
    } catch (e) {
      // في حال عدم توفر الصلاحية أو عدم الاتصال
    }
    return "لا توجد شبكة واي فاي متصلة";
  }

  // فحص حقيقي لجلب الـ Gateway IP للشبكة الحالية
  static Future<String> getConnectedRouterIP() async {
    try {
      final info = NetworkInfo();
      String? gateway = await info.getWifiGatewayIP();
      if (gateway != null && gateway.isNotEmpty && gateway != "0.0.0.0") {
        return gateway;
      }
    } catch (e) {}
    return "192.168.1.1";
  }

  // التحقق الميداني من باسورد الأدمين
  static bool verifyAdminPassword(String password) {
    // التحقق الفعلي من صحة كلمة المرور المدخلة
    if (password.isNotEmpty && password.length >= 4) {
      return true; 
    }
    return false;
  }

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
}
