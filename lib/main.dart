import 'package:flutter/material.dart';
import 'package:flutter_live_streaming/screens/home_screen.dart';
import 'package:flutter_live_streaming/screens/live_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue, accentColor: Color(0xfff160C2F)),
      home: HomeScreen(),
    );
  }
}
