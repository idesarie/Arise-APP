import 'package:flutter/material.dart';

class SoundSelectionPage extends StatelessWidget {
  final List<Map<String, String>> soundOptions;
  final void Function(String) onSelectSound;

  const SoundSelectionPage({
    super.key,
    required this.soundOptions,
    required this.onSelectSound,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Sound')),
      body: ListView.builder(
        itemCount: soundOptions.length,
        itemBuilder: (context, index) {
          final sound = soundOptions[index];
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(sound['label']!),
            onTap: () {
              onSelectSound(sound['value']!);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
