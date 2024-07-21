import 'dart:convert';
import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:arise_alarm_app/pages/edit_alarm.dart';
import 'package:arise_alarm_app/pages/ring_screen.dart';
import 'package:arise_alarm_app/utils/components/filter_popup_menu.dart';
import 'package:arise_alarm_app/utils/tile.dart';
import 'package:arise_alarm_app/wrapper/wrap_alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late List<CustomAlarmSettings> customAlarms = [];
  late List<CustomAlarmSettings> allAlarms = [];
  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    super.initState();
    if (Alarm.android) {
      checkAndroidNotificationPermission();
      checkAndroidScheduleExactAlarmPermission();
    }
    loadAlarms();
    subscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
  }

  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('alarm_')).toList();

    final loadedAlarms = <CustomAlarmSettings>[];
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final alarmData = jsonDecode(jsonString);
        DateTime dateTime = DateTime.parse(alarmData['dateTime']);

        if (dateTime.isBefore(DateTime.now())) {
          // Reschedule alarm to the same time on the next day
          dateTime = dateTime.add(Duration(days: 1));
        }

        final alarmSettings = AlarmSettings(
          id: alarmData['id'],
          dateTime: dateTime,
          loopAudio: alarmData['loopAudio'],
          vibrate: alarmData['vibrate'],
          volume: alarmData['volume'],
          assetAudioPath: alarmData['assetAudioPath'],
          notificationTitle: 'Alarm',
          notificationBody: 'Your alarm is ringing',
        );

        final customAlarm = CustomAlarmSettings(
          alarmSettings: alarmSettings,
          label: alarmData['label'],
          isActive: alarmData['isActive'],
        );

        loadedAlarms.add(customAlarm);
      }
    }

    setState(() {
      allAlarms = loadedAlarms;
      customAlarms = List.from(allAlarms);
      customAlarms.sort((a, b) => a.alarmSettings.dateTime.compareTo(b.alarmSettings.dateTime));
    });
  }

  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final res = await Permission.notification.request();
      print('Notification permission ${res.isGranted ? '' : 'not '}granted');
    }
  }

  Future<void> checkAndroidScheduleExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      final res = await Permission.scheduleExactAlarm.request();
      print('Schedule exact alarm permission ${res.isGranted ? '' : 'not'} granted');
    }
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AlarmRingScreen(
          alarmSettings: alarmSettings,
        ),
      ),
    );
    loadAlarms();
  }

  Future<void> navigateToAlarmScreen(CustomAlarmSettings? customSettings) async {
    final res = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(customAlarmSettings: customSettings),
      ),
    );
    if (res != null && res == true) {
      // Debugging: Print current alarm settings after update
      if (customSettings != null) {
        print("Updated alarm settings: ${customSettings.alarmSettings.dateTime}");
      }
      loadAlarms();
    }
  }

  void filterAlarms(String choice) {
    setState(() {
      if (choice == 'Default') {
        customAlarms = List.from(allAlarms);
      } else if (choice == 'Active') {
        customAlarms = allAlarms.where((alarm) => alarm.isActive).toList();
      }
      customAlarms.sort((a, b) => a.alarmSettings.dateTime.compareTo(b.alarmSettings.dateTime));
    });
  }

  void toggleAlarmSwitch(CustomAlarmSettings customAlarm, bool isActive) async {
    AlarmSettings alarmSettings = customAlarm.alarmSettings;
    if (isActive) {
      if (alarmSettings.dateTime.isBefore(DateTime.now())) {
        alarmSettings = AlarmSettings(
          id: alarmSettings.id,
          dateTime: alarmSettings.dateTime.add(Duration(days: 1)),
          loopAudio: alarmSettings.loopAudio,
          vibrate: alarmSettings.vibrate,
          volume: alarmSettings.volume,
          assetAudioPath: alarmSettings.assetAudioPath,
          notificationTitle: alarmSettings.notificationTitle,
          notificationBody: alarmSettings.notificationBody,
        );
      }

      final success = await Alarm.set(alarmSettings: alarmSettings);
      if (success) {
        print("Alarm set successfully.");
      } else {
        print("Failed to set the alarm.");
      }
    } else {
      final success = await Alarm.stop(alarmSettings.id);
      if (success) {
        print("Alarm stopped successfully.");
      } else {
        print("Failed to stop the alarm.");
      }
    }
    // =====================================================
    //
    // Update SharedPreferences with the latest settings
    //
    // =====================================================

    final prefs = await SharedPreferences.getInstance();
    final alarmData = customAlarmSettingsToMap(CustomAlarmSettings(
      alarmSettings: alarmSettings,
      label: customAlarm.label,
      isActive: isActive,
    ));
    await prefs.setString('alarm_${alarmSettings.id}', jsonEncode(alarmData));
    loadAlarms();
  }
  

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          FilterPopupMenu(
            onSelected: filterAlarms,
            options: ['Default', 'Active'],
          ),
        ],
      ),
      body: SafeArea(
        child: customAlarms.isNotEmpty
            ? ListView.separated(
                itemCount: customAlarms.length,
                separatorBuilder: (context, index) => SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final alarm = customAlarms[index];
                  return AlarmTile(
                    key: Key(alarm.alarmSettings.id.toString()),
                    title: TimeOfDay(
                      hour: alarm.alarmSettings.dateTime.hour,
                      minute: alarm.alarmSettings.dateTime.minute,
                    ).format(context),
                    isSwitched: alarm.isActive,
                    onToggleSwitch: (isActive) => toggleAlarmSwitch(alarm, isActive),
                    onPressed: () => navigateToAlarmScreen(alarm),
                    label: alarm.label,
                    dateTime: alarm.alarmSettings.dateTime,
                    onDismissed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('alarm_${alarm.alarmSettings.id}');
                      loadAlarms();
                    },
                  );
                },
              )
            : Center(
                child: Text(
                  'No alarms set',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              shape: CircleBorder(side: BorderSide.none, eccentricity: 0.0),
              onPressed: () => navigateToAlarmScreen(null),
              child: const Icon(Icons.add, size: 33),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }




  Map<String, dynamic> customAlarmSettingsToMap(CustomAlarmSettings customSettings) {
    return {
      'id': customSettings.alarmSettings.id,
      'dateTime': customSettings.alarmSettings.dateTime.toIso8601String(),
      'loopAudio': customSettings.alarmSettings.loopAudio,
      'vibrate': customSettings.alarmSettings.vibrate,
      'volume': customSettings.alarmSettings.volume,
      'assetAudioPath': customSettings.alarmSettings.assetAudioPath,
      'label': customSettings.label,
      'isActive': customSettings.isActive,
    };
  }
}
