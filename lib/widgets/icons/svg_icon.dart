import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String assetName;

  const SvgIcon(this.assetName, {super.key});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24.0;
    final opacity = iconTheme.opacity ?? 1.0;
    var color = iconTheme.color!;
    if (opacity != 1.0) {
      color = color.withValues(alpha: color.a * opacity);
    }

    return SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
