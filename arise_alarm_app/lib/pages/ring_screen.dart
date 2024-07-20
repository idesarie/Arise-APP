import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

class AlarmRingScreen extends StatelessWidget {
  const AlarmRingScreen({
    required this.alarmSettings,
    super.key,
  });

  final AlarmSettings alarmSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Your alarm is ringing...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text('🔔', style: TextStyle(fontSize: 50)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RawMaterialButton(
                  onPressed: () {
                    final now = DateTime.now();
                    final snoozeTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      now.hour,
                      now.minute,
                    ).add(const Duration(minutes: 1));

                    Alarm.set(
                      alarmSettings: alarmSettings.copyWith(
                        dateTime: snoozeTime,
                      ),
                    ).then((_) => Navigator.pop(context));
                  },
                  child: Text(
                    'Snooze',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    Alarm.stop(alarmSettings.id).then((_) {
                      Navigator.pop(context);
                    });
                  },
                  child: Text(
                    'Stop',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
