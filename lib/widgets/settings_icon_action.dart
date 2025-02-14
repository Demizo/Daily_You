import 'package:flutter/material.dart';

class SettingsIconAction extends StatelessWidget {
  final String title;
  final String? hint;
  final Icon icon;
  final Icon? secondaryIcon;
  final Function() onPressed;
  final Function()? onSecondaryPressed;

  const SettingsIconAction({
    super.key,
    required this.title,
    this.hint,
    required this.icon,
    this.secondaryIcon,
    required this.onPressed,
    this.onSecondaryPressed
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16),
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: TextStyle(fontSize: 14),
                ),
            ],
          ),
        ),
        IconButton(onPressed: onPressed, icon: icon),
	if (secondaryIcon != null && onSecondaryPressed != null)
	  IconButton(onPressed: onSecondaryPressed, icon: secondaryIcon!)
      ],
    );
  }
}
