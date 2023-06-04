import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'Screen/Homepage/homePage.dart';

Future<void> main() async {
  await ScreenUtil.ensureScreenSize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final List<String> items = [
    'Brigthness',
    'Greyscale',
  ];

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        home: homePage(
          items: items,
        ));
  }
}
