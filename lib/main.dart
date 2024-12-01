import 'package:flutter/material.dart';
import 'auth/Login.dart';
import 'auth/Register.dart';
void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loan Scope',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(),
      routes:  {
        '/login' : (context) => LoginPage(),
        '/register' : (context) => RegisterPage(),
      },
    );
  }
}

