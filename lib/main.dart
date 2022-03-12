import 'package:flutter/material.dart';
import 'package:shihab/pages/home_page.dart';
import 'package:shihab/utils/utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora live streaming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: primaryColor, accentColor: Color(0xfff160C2F)),
      home: HomePage(),
    );
  }
}
