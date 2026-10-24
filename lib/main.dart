import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  // التقاط أي خطأ يحدث في التطبيق لمنع الانهيار المفاجئ
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RouterManagerApp());
}

class RouterManagerApp extends StatelessWidget {
  const RouterManagerApp({Key? key}) : super(key: key);

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
