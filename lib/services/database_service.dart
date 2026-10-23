// خدمة حفظ واسترجاع بيانات المشتركين محلياً على الجهاز
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const String _storageKey = 'saved_subscribers_list';

  // حفظ قائمة المشتركين
  static Future<void> saveSubscribers(List<Map<String, dynamic>> subscribers) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(subscribers);
    await prefs.setString(_storageKey, jsonString);
  }

  // استرجاع قائمة المشتركين المحفوظة
  static Future<List<Map<String, dynamic>>> loadSubscribers() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      // القائمة الافتراضية إذا لم تكن هناك بيانات محفوظة مسبقاً
      return [
        {
          "name": "المشترك: أحمد (حي الحسين)",
          "type": "Huawei ONT (ضوئي)",
          "ip": "192.168.1.1",
          "status": "ممتازة (-19.2 dBm)",
        },
        {
          "name": "المشترك: علي كريم (الرئيسية)",
          "type": "TP-Link Archer C80",
          "ip": "192.168.0.1",
          "status": "متصل (1Gbps)",
        },
      ];
    }

    List<dynamic> decodedList = jsonDecode(jsonString);
    return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
