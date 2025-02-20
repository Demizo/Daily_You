import 'package:flutter/material.dart';

class SettingsHeader extends StatelessWidget {
  final String text;
  const SettingsHeader({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
    );
  }
}
