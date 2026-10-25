import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const String _storageKey = 'saved_subscribers_list_v2';

  // حفظ قائمة المشتركين مع تفاصيل الراوتر والـ IP والإشارة //
  static Future<void> saveSubscribers(List<Map<String, dynamic>> subscribers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String jsonString = jsonEncode(subscribers);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print("Error saving subscribers: $e");
    }
  }

  // استرجاع قائمة المشتركين المحفوظين //
  static Future<List<Map<String, dynamic>>> loadSubscribers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return _getDefaultSubscribers();
      }

      List<dynamic> decodedList = jsonDecode(jsonString);
      return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print("Error loading subscribers, returning defaults: $e");
      return _getDefaultSubscribers();
    }
  }

  // إضافة مشترك جديد أو راوتر تم الاتصال به حديثاً للميدان //
  static Future<void> addSubscriber({
    required String name,
    required String type,
    required String ip,
    required String status,
  }) async {
    List<Map<String, dynamic>> currentList = await loadSubscribers();
    
    // إضافة المشترك الجديد بالبداية //
    currentList.insert(0, {
      "name": name,
      "type": type,
      "ip": ip,
      "status": status,
    });

    await saveSubscribers(currentList);
  }

  // القائمة الافتراضية //
  static List<Map<String, dynamic>> _getDefaultSubscribers() {
    return [
      {
        "name": "المشترك: أحمد (حي الحسين)",
        "type": "Huawei ONT",
        "ip": "192.168.1.1",
        "status": "ممتاز (-19.2 dBm)",
      },
      {
        "name": "المشترك: علي كريم (الرئيسية)",
        "type": "TP-Link Archer C80",
        "ip": "192.168.0.1",
        "status": "متصل (1Gbps)",
      },
    ];
  }
}
