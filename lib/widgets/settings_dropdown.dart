import 'package:flutter/material.dart';

class SettingsDropdown<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> options;
  final Function(T?) onChanged;
  final DropdownButtonBuilder? selectedItemBuilder;
  final IconData? leadingIcon;

  const SettingsDropdown({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.selectedItemBuilder,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownButton<T>(
        underline: Container(),
        elevation: 1,
        isDense: true,
        isExpanded: false,
        alignment: AlignmentDirectional.centerEnd,
        borderRadius: BorderRadius.circular(20),
        value: value,
        items: options,
        selectedItemBuilder: selectedItemBuilder,
        onChanged: onChanged);

    if (leadingIcon != null) {
      return ListTile(
        leading: Icon(leadingIcon),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: dropdown,
      );
    }

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
          dropdown,
        ],
      ),
    );
  }
}
