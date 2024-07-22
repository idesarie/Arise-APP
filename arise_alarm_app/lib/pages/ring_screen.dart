import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:arise_alarm_app/pages/activities_screen/math_challenge_screen.dart';

class AlarmRingScreen extends StatelessWidget {
  const AlarmRingScreen({
    required this.activityType,
    required this.alarmSettings,
    super.key,
  });

  final AlarmSettings alarmSettings;
  final String activityType;
  
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
              ],
            ),
            ElevatedButton(
              onPressed: () {
                if (activityType == "Math") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MathChallengeScreen(
                        onSuccess: () {
                          Alarm.stop(alarmSettings.id).then((_) {
                            Navigator.pop(context);
                          });
                        },
                      ),
                    ),
                  );
                } else {
                  Alarm.stop(alarmSettings.id).then((_) {
                    Navigator.pop(context);
                  });
                }
              },
              child: Text(
                activityType == "None" ? "Stop" : activityType,  // Dynamic button label
              ),
            ),
          ],
        ),
      ),
    );
  }
}
