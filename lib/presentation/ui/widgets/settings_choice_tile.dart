import 'package:flutter/material.dart';

class SettingsChoiceTile<T> extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: DropdownButton<T>(
        value: value,
        items: options
            .map((o) => DropdownMenuItem<T>(
                  value: o,
                  child: Text(labelOf(o)),
                ))
            .toList(growable: false),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}