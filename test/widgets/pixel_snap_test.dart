// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/pixel_snap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _OriginRecorder extends CustomPainter {
  _OriginRecorder(this.origins);

  final List<Offset> origins;

  @override
  void paint(Canvas canvas, Size size) {
    final transform = canvas.getTransform();
    origins.add(Offset(transform[12], transform[13]));
  }

  @override
  bool shouldRepaint(_OriginRecorder old) => true;
}

void main() {
  Widget snapped(List<Offset> origins, {required double left, double top = 0}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 2),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(left: left, top: top),
            child: PixelSnap(
              child: CustomPaint(
                size: const Size(10, 10),
                painter: _OriginRecorder(origins),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('paints the child on a whole device pixel', (tester) async {
    final origins = <Offset>[];

    await tester.pumpWidget(snapped(origins, left: 10.3, top: 20.2));

    expect(origins.last, const Offset(10.5, 20.0));
  });

  testWidgets('leaves an already aligned child where it is', (tester) async {
    final origins = <Offset>[];

    await tester.pumpWidget(snapped(origins, left: 10.5, top: 20));

    expect(origins.last, const Offset(10.5, 20.0));
  });

  testWidgets('re-snaps as an ancestor scrolls by a fractional amount',
      (tester) async {
    final origins = <Offset>[];
    final controller = ScrollController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 2),
        child: SizedBox(
          height: 100,
          child: ListView(
            controller: controller,
            children: [
              PixelSnap(
                child: CustomPaint(
                  size: const Size(10, 40),
                  painter: _OriginRecorder(origins),
                ),
              ),
              const SizedBox(height: 3000),
            ],
          ),
        ),
      ),
    ));

    for (final offset in [0.0, 0.3, 0.6, 0.9]) {
      controller.jumpTo(offset);
      await tester.pump();
      expect(controller.offset, offset);
      final deviceY = (origins.last.dy - offset) * 2;
      expect(deviceY, closeTo(deviceY.roundToDouble(), 1e-4),
          reason: 'scroll $offset painted at $deviceY device pixels');
    }
  });
}
