import 'package:flutter/material.dart';

class FilterPopupMenu extends StatelessWidget {
  final Function(String) onSelected;
  final List<String> options;
  final String label;

  const FilterPopupMenu({
    Key? key,
    required this.onSelected,
    required this.options,
    this.label = "Filter",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Icon(Icons.swap_vert),
              ],
            ),
          ),
          ...options.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList(),
        ];
      },
      icon: Icon(Icons.more_horiz),
    );
  }
}
