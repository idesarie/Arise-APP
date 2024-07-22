
import 'package:alarm/alarm.dart';
import 'package:arise_alarm_app/pages/settings_page.dart';
import 'package:arise_alarm_app/pages/sleep_page.dart';
import 'package:arise_alarm_app/utils/splashscreen.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Alarm.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const SplashScreen(),
    );
  }
}