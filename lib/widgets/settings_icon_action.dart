import 'package:flutter/material.dart';

class SettingsIconAction extends StatelessWidget {
  final String title;
  final Icon icon;
  final Function() onPressed;

  const SettingsIconAction({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
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
        IconButton(onPressed: onPressed, icon: icon)
      ],
    );
  }
}
