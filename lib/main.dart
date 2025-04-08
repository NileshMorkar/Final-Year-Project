import 'package:flutter/material.dart';
import 'package:medi_1/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medi App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MainScreen(),
    );
  }
}
