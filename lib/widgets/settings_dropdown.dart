import 'package:daily_you/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final configProvider = Provider.of<ConfigProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          DropdownButton<T>(
              underline: Container(),
              elevation: 1,
              isDense: true,
              isExpanded: false,
              alignment: AlignmentDirectional.centerEnd,
              borderRadius: BorderRadius.circular(20),
              value: configProvider.get(settingsKey),
              items: options,
              onChanged: onChanged),
        ],
      ),
    );
  }
}
