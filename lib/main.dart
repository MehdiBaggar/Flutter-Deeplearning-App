import 'package:flutter/material.dart';
import 'package:elmehdibaggar_app/screens/home_page.dart';
import 'package:elmehdibaggar_app/screens/register_page.dart';
import 'package:elmehdibaggar_app/screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/ClothesClassifier_page.dart';
import 'screens/FruitClassifier_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Baggar El Mehdi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/fruitClassifier': (context) => FruitClassifierPage(),
        '/ClothesClassifier': (context) => ClothesClassifierPage(),
      },
      initialRoute: '/login',
    );
  }
}
