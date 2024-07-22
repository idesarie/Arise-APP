import 'dart:convert';
import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:arise_alarm_app/pages/edit_alarm.dart';
import 'package:arise_alarm_app/pages/ring_screen.dart';
import 'package:arise_alarm_app/utils/components/filter_popup_menu.dart';
import 'package:arise_alarm_app/utils/tile.dart';
import 'package:arise_alarm_app/classes/wrap_alarm_settings.dart';
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
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    if (Alarm.android) {
      _checkPermissions();
    }
    _initializePreferences();
    subscription ??= Alarm.ringStream.stream.listen(_navigateToRingScreen);
  }

  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final keys = prefs.getKeys().where((key) => key.startsWith('alarm_')).toList();
    final loadedAlarms = <CustomAlarmSettings>[];

    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final alarmData = jsonDecode(jsonString);
        DateTime dateTime = DateTime.parse(alarmData['dateTime']);

        if (dateTime.isBefore(DateTime.now())) {
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
          activityType: alarmData['activityType']
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

  Future<void> _checkPermissions() async {
    await Future.wait([
      _checkPermission(Permission.notification),
      _checkPermission(Permission.scheduleExactAlarm),
    ]);
  }

  Future<void> _checkPermission(Permission permission) async {
    final status = await permission.status;
    if (status.isDenied) {
      final res = await permission.request();
      print('${permission.toString()} permission ${res.isGranted ? '' : 'not '}granted');
    }
  }

    Future<void> _navigateToRingScreen(AlarmSettings alarmSettings) async {
    print('Navigating to ring screen with alarmSettings: $alarmSettings');
    final customAlarm = allAlarms.firstWhere((alarm) => alarm.alarmSettings.id == alarmSettings.id);
    print('Custom alarm found: $customAlarm');
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AlarmRingScreen(
          alarmSettings: alarmSettings,
          activityType: customAlarm.activityType,
        ),
      ),
    );
    print('Returned from ring screen');
    _loadAlarms();
  }
    
  Future<void> _navigateToAlarmScreen(CustomAlarmSettings? customSettings) async {
    final res = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(customAlarmSettings: customSettings),
      ),
    );
    if (res == true) {
      _loadAlarms();
    }
  }

  void _filterAlarms(String choice) {
    setState(() {
      customAlarms = choice == 'Default'
          ? List.from(allAlarms)
          : allAlarms.where((alarm) => alarm.isActive).toList();
      customAlarms.sort((a, b) => a.alarmSettings.dateTime.compareTo(b.alarmSettings.dateTime));
    });
  }

  Future<void> _toggleAlarmSwitch(CustomAlarmSettings customAlarm, bool isActive) async {
    AlarmSettings alarmSettings = customAlarm.alarmSettings;

    if (isActive) {
      if (alarmSettings.dateTime.isBefore(DateTime.now())) {
        alarmSettings = alarmSettings.copyWith(
          dateTime: alarmSettings.dateTime.add(Duration(days: 1)),
        );
      }

      final success = await Alarm.set(alarmSettings: alarmSettings);
      print(success ? "Alarm set successfully." : "Failed to set the alarm.");
    } else {
      final success = await Alarm.stop(alarmSettings.id);
      print(success ? "Alarm stopped successfully." : "Failed to stop the alarm.");
    }

    final alarmData = _customAlarmSettingsToMap(CustomAlarmSettings(
      alarmSettings: alarmSettings,
      label: customAlarm.label,
      isActive: isActive,
      activityType: customAlarm.activityType
    ));
    await prefs.setString('alarm_${alarmSettings.id}', jsonEncode(alarmData));
    setState(() {
      _loadAlarms();
    });
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
            onSelected: _filterAlarms,
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
                    onToggleSwitch: (isActive) => _toggleAlarmSwitch(alarm, isActive),
                    onPressed: () => _navigateToAlarmScreen(alarm),
                    label: alarm.label,
                    dateTime: alarm.alarmSettings.dateTime,
                    activityType: alarm.activityType,
                    onDismissed: () async {
                      await prefs.remove('alarm_${alarm.alarmSettings.id}');
                      _loadAlarms();
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
              onPressed: () => _navigateToAlarmScreen(null),
              child: const Icon(Icons.add, size: 33),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Map<String, dynamic> _customAlarmSettingsToMap(CustomAlarmSettings customSettings) {
    return {
      'id': customSettings.alarmSettings.id,
      'dateTime': customSettings.alarmSettings.dateTime.toIso8601String(),
      'loopAudio': customSettings.alarmSettings.loopAudio,
      'vibrate': customSettings.alarmSettings.vibrate,
      'volume': customSettings.alarmSettings.volume,
      'assetAudioPath': customSettings.alarmSettings.assetAudioPath,
      'label': customSettings.label,
      'isActive': customSettings.isActive,
      'activityType': customSettings.activityType,
    };
  }
}
