import 'package:flutter/material.dart';

class AlarmTile extends StatefulWidget {
  const AlarmTile({
    required this.title,
    required this.onPressed,
    super.key,
    this.onDismissed,
  });

  final String title;
  final void Function() onPressed;
  final void Function()? onDismissed;

  @override
  State<AlarmTile> createState() => _AlarmTileState();
}

class _AlarmTileState extends State<AlarmTile> {

  bool _isSwitched = true;

  void _toggleSwitch(bool value) {
    setState(() {
      _isSwitched = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.title),
      direction: widget.onDismissed != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        color: Colors.redAccent,
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
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
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
