import 'package:arise_alarm_app/utils/consts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final WeatherFactory wf = WeatherFactory(OPENWEATHER_API_KEY);
  Weather? _weather;
  bool isSleepAlarmActive = false;
  DateTime selectedSleepTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSleepAlarmState();
    wf.currentWeatherByCityName("Philippines").then((w) {
      setState(() {
        _weather = w;
      });
    });
  }

  void _loadSleepAlarmState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isActive = prefs.getBool('isSleepAlarmActive');
    String? sleepTimeString = prefs.getString('selectedSleepTime');

    if (isActive != null) {
      setState(() {
        isSleepAlarmActive = isActive;
      });
    }

    if (sleepTimeString != null) {
      setState(() {
        selectedSleepTime = DateTime.parse(sleepTimeString);
      });
    }
  }

  void _toggleSleepAlarm(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isSleepAlarmActive = value;
    });
    prefs.setBool('isSleepAlarmActive', isSleepAlarmActive);

      if (isSleepAlarmActive) {
        // Ensure the time is in the future
        if (selectedSleepTime.isBefore(DateTime.now())) {
          selectedSleepTime = selectedSleepTime.add(Duration(days: 1));
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('selectedSleepTime', selectedSleepTime.toIso8601String());
        }
        _scheduleAlarm();
      } else {
        await Alarm.stop(42); // Stop the alarm if it's being turned off
        print('Alarm stopped.');
      }
    }

    void _scheduleAlarm() async {
      // Check if selectedSleepTime is in the future
      if (selectedSleepTime.isBefore(DateTime.now())) {
        selectedSleepTime = selectedSleepTime.add(Duration(days: 1));
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('selectedSleepTime', selectedSleepTime.toIso8601String());
      }

      final alarmSettings = AlarmSettings(
        id: 42,
        dateTime: selectedSleepTime,
        assetAudioPath: 'assets/sounds/hintnotification.wav',
        loopAudio: false,
        vibrate: true,
        volume: 0.5,
        notificationTitle: 'Sleep Time',
        notificationBody: 'It\'s time to go to sleep!',
        enableNotificationOnKill: false,
      );

      await Alarm.set(alarmSettings: alarmSettings);
      print('Alarm scheduled for ${alarmSettings.dateTime}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sleep Time Notification is set to ${alarmSettings.dateTime}')));
    }


  Future<void> _pickSleepTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedSleepTime),
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        selectedSleepTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        if (selectedSleepTime.isBefore(now)) {
          selectedSleepTime = selectedSleepTime.add(Duration(days: 1));
        }
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('selectedSleepTime', selectedSleepTime.toIso8601String());

      if (isSleepAlarmActive) {
        _scheduleAlarm();
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _buildUI(),
      ),
    );
  }

  Widget _buildUI() {
    if (_weather == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height / 0.25,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          _dateTimeInfo(),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.08,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              weatherIcon(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _currentTemp(),
                  SizedBox(height: 10),
                  _locationHeader(),
                ],
              )
            ],
          ),
          SizedBox(height: 20),
          _sleepTile(),
        ],
      ),
    );
  }

  Widget _sleepTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.amber),
        child: ListTile(
          title: Text(
            'Sleep Alarm',
            style: TextStyle(fontSize: 20),
          ),
          subtitle: Text(
            DateFormat('hh:mm a').format(selectedSleepTime),
            style: TextStyle(fontSize: 16),
          ),
          trailing: Switch(
            value: isSleepAlarmActive,
            onChanged: _toggleSleepAlarm,
          ),
          onTap: _pickSleepTime,
        ),
      ),
    );
  }

  Widget _locationHeader() {
    return Text(
      _weather?.areaName ?? "",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _dateTimeInfo() {
    DateTime now = DateTime.now();
    String greeting;
    int currentHour = now.hour;

    if (currentHour < 12) {
      greeting = 'Good morning!';
    } else if (currentHour < 18) {
      greeting = 'Good afternoon!';
    } else {
      greeting = 'Good evening!';
    }

    return Column(
      children: [
        Text(
          greeting,
          style: TextStyle(fontSize: 35),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMMM d').format(now),
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(width: 10),
            Text(
              DateFormat('EEEE').format(now),
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        SizedBox(height: 10),
        // Text(
        //   DateFormat('hh:mm a').format(now),
        //   style: TextStyle(fontSize: 35),
        // ),
      ],
    );
  }

  Widget weatherIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage("http://openweathermap.org/img/wn/${_weather?.weatherIcon}@4x.png"),
            ),
          ),
        ),
        Text(
          _weather?.weatherDescription ?? "",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _currentTemp() {
    return Text(
      "${_weather?.temperature?.celsius?.toStringAsFixed(0)}° C",
      style: TextStyle(fontSize: 30),
    );
  }
}
