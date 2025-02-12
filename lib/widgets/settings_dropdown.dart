import 'package:daily_you/config_manager.dart';
import 'package:flutter/material.dart';

class SettingsDropdown<T> extends StatelessWidget {
  final String title;
  final String settingsKey;
  final List<DropdownMenuItem<T>> options;
  final Function(T?) onChanged;

  const SettingsDropdown({
    super.key,
    required this.title,
    required this.settingsKey,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16),
        ),
        DropdownButton<T>(
            underline: Container(),
            elevation: 1,
            isDense: false,
            isExpanded: false,
            alignment: AlignmentDirectional.centerEnd,
            borderRadius: BorderRadius.circular(20),
            value: ConfigManager.instance.getField(settingsKey),
            items: options,
            onChanged: onChanged),
      ],
    );
  }
}
