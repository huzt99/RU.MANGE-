// الشاشة الرئيسية ونقطة بداية التطبيق
import 'package:flutter/material.dart';
import 'package:ru_mange/screens/home_screen.dart';

void main() async {
  // ضمان تهيئة محرك فلاتر وربطه بالنظام قبل تشغيل أي شيء
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(RouterManagerApp());
}

class RouterManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة الراوترات والمشتركين',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo', // إذا أردت استخدام الخط الموحد
      ),
      home: HomeScreen(),
    );
  }
}
