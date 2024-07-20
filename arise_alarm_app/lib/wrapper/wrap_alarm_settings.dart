import 'package:alarm/model/alarm_settings.dart';

class CustomAlarmSettings {
  final AlarmSettings alarmSettings;
  String label;
  bool isActive;

  CustomAlarmSettings({
    required this.alarmSettings,
    this.label = '',
    this.isActive = false,
  });
}
