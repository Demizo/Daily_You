import 'package:daily_you/config_manager.dart';
import 'package:flutter/material.dart';

class SettingsToggle extends StatelessWidget {
  final String title;
  final String settingsKey;
  final Function(bool) onChanged;

  const SettingsToggle({
    super.key,
    required this.title,
    required this.settingsKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 16),
          ),
        ),
        Switch(
            value: ConfigManager.instance.getField(settingsKey),
            onChanged: onChanged)
      ],
    );
  }
}
