import 'package:flutter/material.dart';
import 'package:ru_mange/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      title: 'إدارة الراوترات والمشتركين',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
