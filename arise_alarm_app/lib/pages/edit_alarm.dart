import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:arise_alarm_app/pages/sound_selection.dart';
import 'package:flutter/material.dart';

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key, this.alarmSettings});

  final AlarmSettings? alarmSettings;

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  bool loading = false;

  late bool creating;
  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late double volume;  // Make volume non-nullable
  late String assetAudio;

  // List of sound options
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
    creating = widget.alarmSettings == null;

    if (creating) {
      selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
      loopAudio = true;
      vibrate = true;
      volume = 0.5;  // Set a default volume
      assetAudio = 'assets/sounds/marimba.mp3';
    } else {
      selectedDateTime = widget.alarmSettings!.dateTime;
      loopAudio = widget.alarmSettings!.loopAudio;
      vibrate = widget.alarmSettings!.vibrate;
      volume = widget.alarmSettings!.volume ?? 0.5; 
      assetAudio = widget.alarmSettings!.assetAudioPath;
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

  AlarmSettings buildAlarmSettings() {
    final id = creating
        ? DateTime.now().millisecondsSinceEpoch % 10000 + 1
        : widget.alarmSettings!.id;

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: selectedDateTime,
      loopAudio: loopAudio,
      vibrate: vibrate,
      volume: volume,
      assetAudioPath: assetAudio,
      notificationTitle: 'Arise',
      notificationBody: 'Your alarm is ringing', // 'Your alarm ($id) is ringing'
      enableNotificationOnKill: Platform.isIOS,
    );
    return alarmSettings;
  }

  void saveAlarm() {
    if (loading) return;
    setState(() => loading = true);
    Alarm.set(alarmSettings: buildAlarmSettings()).then((res) {
      if (res) Navigator.pop(context, true);
      setState(() => loading = false);
    });
  }

  void deleteAlarm() {
    Alarm.stop(widget.alarmSettings!.id).then((res) {
      if (res) Navigator.pop(context, true);
    });
  }

  void _selectSound() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
              // Vibrate icon and volume slider in one row
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
              if (!creating)
                TextButton(
                  onPressed: deleteAlarm,
                  child: Text(
                    'Delete Alarm',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: const Color.fromARGB(255, 255, 255, 255)),
                  ),
                ),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
