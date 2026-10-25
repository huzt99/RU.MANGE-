import 'package:flutter/material.dart';
import 'package:ru_mange/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // التقاط أي خطأ برمجياً لمنع الانهيار الفوري
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(const RouterManagerApp());
}

class RouterManagerApp extends StatelessWidget {
  const RouterManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RU-Mange',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const SafeHomeWrapper(),
    );
  }
}

// غلاف آمن لحماية التطبيق من الانهيار عند الفتح
class SafeHomeWrapper extends StatelessWidget {
  const SafeHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return HomeScreen();
    } catch (e) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'خطأ في تحميل الشاشة: $e',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}
