import 'package:flutter/material.dart';
import 'package:ru_mange/screens/home_screen.dart';

void main() async {
  // التأكد التام من تهيئة بيئة فلاتر قبل أي عملية تخزين أو شبكة
  WidgetsFlutterBinding.ensureInitialized();
  
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
      home: const HomeScreen(),
    );
  }
}
