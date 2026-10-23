// هذا هو نقطة البداية لتشغيل التطبيق بالكامل
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
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
      ),
      home: HomeScreen(),
    );
  }
}
