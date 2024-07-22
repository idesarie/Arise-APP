import 'package:alarm/model/alarm_settings.dart';

class CustomAlarmSettings {
  final AlarmSettings alarmSettings;
  final String label;
  final bool isActive;
  final String activityType;

  CustomAlarmSettings({
    required this.alarmSettings,
    required this.label,
    required this.isActive,
    required this.activityType,
  });
}
