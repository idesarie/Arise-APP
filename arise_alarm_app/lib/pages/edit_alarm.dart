import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:arise_alarm_app/pages/sound_selection.dart';
import 'package:arise_alarm_app/wrapper/wrap_alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({
    super.key,
    this.customAlarmSettings,
  });

  final CustomAlarmSettings? customAlarmSettings;

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  bool loading = false;
  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late double volume;
  late String assetAudio;
  late String label = 'Alarm';

  final List<Map<String, String>> soundOptions = [
    {'value': 'assets/sounds/marimba.mp3', 'label': 'Marimba'},
    {'value': 'assets/sounds/nokia.mp3', 'label': 'Nokia'},
    {'value': 'assets/sounds/mozart.mp3', 'label': 'Mozart'},
    {'value': 'assets/sounds/star_wars.mp3', 'label': 'Star Wars'},
    {'value': 'assets/sounds/one_piece.mp3', 'label': 'One Piece'},
    {'value': 'assets/sounds/alertinhall.wav', 'label': 'Alert in Hall'},
    {'value': 'assets/sounds/classicalarm.wav', 'label': 'Classical Arm'},
    {'value': 'assets/sounds/facilityalarm.wav', 'label': 'Facility Alarm'},
    {'value': 'assets/sounds/hintnotification.wav', 'label': 'Hint Notification'},
    {'value': 'assets/sounds/retrogame.wav', 'label': 'Retro Game'},
    {'value': 'assets/sounds/rooster.wav', 'label': 'Rooster'},
    {'value': 'assets/sounds/alarm.wav', 'label': 'Alarm'},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.customAlarmSettings == null) {
      // Creating a new alarm
      selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
      loopAudio = true;
      vibrate = true;
      volume = 0.5;
      assetAudio = 'assets/sounds/marimba.mp3';
      label = '';
    } else {
      // Editing an existing alarm
      final settings = widget.customAlarmSettings!.alarmSettings;
      selectedDateTime = settings.dateTime;
      loopAudio = settings.loopAudio;
      vibrate = settings.vibrate;
      volume = settings.volume ?? 0.5;
      assetAudio = settings.assetAudioPath;
      label = widget.customAlarmSettings!.label;
    }
  }

   String getDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = selectedDateTime.difference(today).inDays;

    switch (difference) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      case 2:
        return 'After tomorrow';
      default:
        return 'In $difference days';
    }
  }
  
  Future<void> pickTime() async {
    final res = await showTimePicker(
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      context: context,
    );

    if (res != null) {
      setState(() {
        final now = DateTime.now();
        selectedDateTime = now.copyWith(
          hour: res.hour,
          minute: res.minute,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
        if (selectedDateTime.isBefore(now)) {
          selectedDateTime = selectedDateTime.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectSound() async {
    final selectedSound = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SoundSelectionPage(
          soundOptions: soundOptions,
          onSelectSound: (sound) {
            setState(() {
              assetAudio = sound;
            });
          },
        ),
      ),
    );
    if (selectedSound != null) {
      setState(() {
        assetAudio = selectedSound;
      });
    }
  }

  AlarmSettings buildAlarmSettings() {
    final id = widget.customAlarmSettings?.alarmSettings.id ??
               DateTime.now().millisecondsSinceEpoch % 10000 + 1;

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: selectedDateTime,
      loopAudio: loopAudio,
      vibrate: vibrate,
      volume: volume,
      assetAudioPath: assetAudio,
      notificationTitle: 'Arise',
      notificationBody: 'Your alarm is ringing',
      enableNotificationOnKill: Platform.isIOS,
    );
    return alarmSettings;
  }

  Future<void> saveAlarm() async {
    if (loading) return;
    setState(() => loading = true);
    if (label.isEmpty) {
    label = 'Alarm';
  }
    final settings = buildAlarmSettings();

    final customSettings = CustomAlarmSettings(
      alarmSettings: settings,
      label: label,
      isActive: true,
    );

    final prefs = await SharedPreferences.getInstance();
    final alarmData = customAlarmSettingsToMap(customSettings);
    if (widget.customAlarmSettings != null) {
      await prefs.remove('alarm_${widget.customAlarmSettings!.alarmSettings.id}');
    }

    // Save new alarm to SP
    await prefs.setString('alarm_${customSettings.alarmSettings.id}', jsonEncode(alarmData));

    // Stop existing alarm if it's being updated
    if (widget.customAlarmSettings != null) {
      Alarm.stop(widget.customAlarmSettings!.alarmSettings.id).then((res) {
        if (res) {
          // Set the new alarm
          Alarm.set(alarmSettings: settings).then((res) {
            if (res) Navigator.pop(context, true);
            setState(() => loading = false);
          });
        } else {
          setState(() => loading = false);
        }
      });
    } else {
      // Set new alarm if it's being created
      Alarm.set(alarmSettings: settings).then((res) {
        if (res) Navigator.pop(context, true);
        setState(() => loading = false);
      });
    }
  }

//Detlete alarm
  Future<void> deleteAlarm() async {
    if (widget.customAlarmSettings != null) {
      final id = widget.customAlarmSettings!.alarmSettings.id;

      Alarm.stop(id).then((res) async {
        if (res) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('alarm_$id');
          Navigator.pop(context, true);
        }
      });
    }
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customAlarmSettings == null ? 'Add Alarm' : 'Edit Alarm')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getDay(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Colors.blueAccent.withOpacity(0.8)),
              ),
              RawMaterialButton(
                onPressed: pickTime,
                fillColor: Colors.grey[200],
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: Text(
                    TimeOfDay.fromDateTime(selectedDateTime).format(context),
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium!
                        .copyWith(color: Colors.blueAccent),
                  ),
                ),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Alarm Label'),
                onChanged: (value) {
                  setState(() {
                    label = value;
                  });
                },
                controller: TextEditingController(text: label),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Loop alarm',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: loopAudio,
                    onChanged: (value) => setState(() => loopAudio = value),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _selectSound,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sound',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      soundOptions.firstWhere((sound) => sound['value'] == assetAudio)['label']!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      vibrate ? Icons.vibration : Icons.vibration_outlined,
                      color: vibrate ? Colors.blueAccent : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        vibrate = !vibrate;
                      });
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: volume,
                      onChanged: (value) {
                        setState(() => volume = value);
                      },
                      min: 0,
                      max: 1,
                    ),
                  ),
                  Icon(
                    volume > 0.7
                        ? Icons.volume_up_rounded
                        : volume > 0.1
                            ? Icons.volume_down_rounded
                            : Icons.volume_mute_rounded,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
              TextButton(
                onPressed: saveAlarm,
                child: loading
                    ? const CircularProgressIndicator()
                    : Text(
                        'Save',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(color: Colors.blueAccent),
                      ),
              ),
              if (widget.customAlarmSettings != null)
                TextButton(
                  onPressed: deleteAlarm,
                  child: Text(
                    'Delete Alarm',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
