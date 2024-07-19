import 'package:arise_alarm_app/pages/alarm_page.dart';
import 'package:arise_alarm_app/pages/report_page.dart';
import 'package:arise_alarm_app/pages/settings_page.dart';
import 'package:arise_alarm_app/pages/sleep_page.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  int index = 0;

  final pages = [
    const AlarmPage(),
    const SleepPage(),
    const ReportPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (index) => setState(() => this.index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.alarm), label: "Home"),
          NavigationDestination(icon: Icon(Icons.bed_rounded), label: "Sleep"),
          NavigationDestination(icon: Icon(Icons.summarize_outlined), label: "Report"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
      body: pages[index],
    );

  }
}