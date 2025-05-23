import 'package:flutter/material.dart';
import 'package:medi_1/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RapidAid',

      theme: ThemeData(primarySwatch: Colors.teal),

      home: const SplashScreen(),
    );
  }
}
