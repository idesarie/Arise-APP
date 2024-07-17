import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      iconSize: 24,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      elevation: 12,
      unselectedItemColor: const Color.fromARGB(119, 31, 25, 25),
      selectedItemColor: const Color.fromARGB(255, 8, 8, 8),
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.alarm_add_outlined),
          label: 'Alarm',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bed_outlined),
          label: 'Sleep',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wb_sunny_outlined),
          label: 'Morning',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}
