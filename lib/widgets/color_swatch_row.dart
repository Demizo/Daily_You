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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(backgroundColor: color, radius: 16),
              Icon(
                Icons.palette_rounded,
                size: 20,
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
