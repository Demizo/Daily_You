import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class PillClipper extends CustomClipper<Path> {
  static Path buildPath(Size size) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.shortestSide / 2),
      ));
  }

  @override
  Path getClip(Size size) => buildPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}

class CookieClipper extends CustomClipper<Path> {
  static Path buildPath(Size size) {
    final s = math.min(size.width, size.height);
    final w = size.width;
    final h = size.height;
    final r = s * 0.18;
    final d = s * 0.13;

    final path = Path();

    path.moveTo(r, 0);
    // top edge with concave midpoint
    path.cubicTo(w / 2 - s * 0.12, 0, w / 2 - s * 0.12, d, w / 2, d);
    path.cubicTo(w / 2 + s * 0.12, d, w / 2 + s * 0.12, 0, w - r, 0);
    // top-right corner
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    // right edge with concave midpoint
    path.cubicTo(w, h / 2 - s * 0.12, w - d, h / 2 - s * 0.12, w - d, h / 2);
    path.cubicTo(w - d, h / 2 + s * 0.12, w, h / 2 + s * 0.12, w, h - r);
    // bottom-right corner
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    // bottom edge with concave midpoint
    path.cubicTo(w / 2 + s * 0.12, h, w / 2 + s * 0.12, h - d, w / 2, h - d);
    path.cubicTo(w / 2 - s * 0.12, h - d, w / 2 - s * 0.12, h, r, h);
    // bottom-left corner
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    // left edge with concave midpoint
    path.cubicTo(0, h / 2 + s * 0.12, d, h / 2 + s * 0.12, d, h / 2);
    path.cubicTo(d, h / 2 - s * 0.12, 0, h / 2 - s * 0.12, 0, r);
    // top-left corner
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.close();
    return path;
  }

  @override
  Path getClip(Size size) => buildPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}

class SoftBurstClipper extends CustomClipper<Path> {
  final int bumps;
  const SoftBurstClipper({this.bumps = 8});

  static Path buildPath(Size size, {int bumps = 8}) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseR = math.min(cx, cy) * 0.72;
    final peakR = math.min(cx, cy) * 0.92;
    final total = bumps * 2;
    final step = 2 * math.pi / total;

    Offset pt(int i) {
      final a = i * step - math.pi / 2;
      final r = (i % 2 == 0) ? peakR : baseR;
      return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
    }

    Offset handle(int i, bool fwd) {
      final a = i * step - math.pi / 2;
      final r = (i % 2 == 0) ? peakR : baseR;
      final ta = a + (fwd ? math.pi / 2 : -math.pi / 2);
      final len = r * math.tan(step / 2) * 0.8;
      return Offset(
          pt(i).dx + len * math.cos(ta), pt(i).dy + len * math.sin(ta));
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 0; i < total; i++) {
      final n = (i + 1) % total;
      path.cubicTo(
        handle(i, true).dx,
        handle(i, true).dy,
        handle(n, false).dx,
        handle(n, false).dy,
        pt(n).dx,
        pt(n).dy,
      );
    }
    return path..close();
  }

  @override
  Path getClip(Size size) => buildPath(size, bumps: bumps);

  @override
  bool shouldReclip(covariant SoftBurstClipper old) => old.bumps != bumps;
}

class MorphingBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  static const int _bumps = 8;

  const MorphingBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseR = math.min(cx, cy) * 0.82;
    final peakR = math.min(cx, cy) * 1.02;
    final circleR = (baseR + peakR) / 2.3;
    final total = _bumps * 2;
    final step = 2 * math.pi / total;

    Offset pt(int i) {
      final a = i * step - math.pi / 2;
      final burstR = (i % 2 == 0) ? peakR : baseR;
      final r = lerpDouble(circleR, burstR, progress)!;
      return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
    }

    Offset handle(int i, bool fwd) {
      final a = i * step - math.pi / 2;
      final burstR = (i % 2 == 0) ? peakR : baseR;
      final r = lerpDouble(circleR, burstR, progress)!;
      final ta = a + (fwd ? math.pi / 2 : -math.pi / 2);
      final len = r * math.tan(step / 2) * 0.8;
      return Offset(
          pt(i).dx + len * math.cos(ta), pt(i).dy + len * math.sin(ta));
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 0; i < total; i++) {
      final n = (i + 1) % total;
      path.cubicTo(
        handle(i, true).dx,
        handle(i, true).dy,
        handle(n, false).dx,
        handle(n, false).dy,
        pt(n).dx,
        pt(n).dy,
      );
    }
    path.close();

    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(MorphingBurstPainter old) =>
      old.progress != progress || old.color != color;
}
