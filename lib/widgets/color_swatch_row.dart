import 'package:flutter/material.dart';

class ColorSwatchRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ColorSwatchRow({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(backgroundColor: color, radius: 16),
        ),
      ],
    );
  }
}
