import 'package:flutter/material.dart';

class SettingsDropdown<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> options;
  final Function(T?) onChanged;

  const SettingsDropdown({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0, right: 16.0),
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
              value: value,
              items: options,
              onChanged: onChanged),
        ],
      ),
    );
  }
}
