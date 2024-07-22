import 'package:flutter/material.dart';

class AlarmTile extends StatefulWidget {
  const AlarmTile({
    required this.title,
    required this.onPressed,
    required this.isSwitched,
    required this.onToggleSwitch,
    required this.label,
    required this.dateTime,
    required this.activityType,
    super.key,
    this.onDismissed,
  });

  final String title;
  final bool isSwitched;
  final String label;
  final DateTime dateTime;
  final String activityType;
  final void Function(bool) onToggleSwitch;
  final void Function() onPressed;
  final void Function()? onDismissed;

  @override
  State<AlarmTile> createState() => _AlarmTileState();
}

class _AlarmTileState extends State<AlarmTile> {
  late bool _isSwitched;

  @override
  void initState() {
    super.initState();
    _isSwitched = widget.isSwitched;
  }

  void _toggleSwitch(bool value) {
    setState(() {
      _isSwitched = value;
    });
    widget.onToggleSwitch(value);
  }

  String _getDayLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = dateTime.difference(today).inDays;

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

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.title),
      direction: widget.onDismissed != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        color: const Color.fromARGB(255, 113, 0, 0),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        child: const Icon(
          Icons.delete,
          size: 30,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => widget.onDismissed?.call(),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            _getDayLabel(widget.dateTime),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${widget.label}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
               Text(
                "${widget.activityType}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          trailing: Switch(
            value: _isSwitched,
            onChanged: _toggleSwitch,
            activeColor: Colors.blue,
            inactiveTrackColor: Colors.grey,
          ),
          onTap: widget.onPressed,
        ),
      ),
    );
  }
}