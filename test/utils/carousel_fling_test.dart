// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/utils/carousel_fling.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

const itemExtent = 168.0;
const tolerance = Tolerance(distance: 0.004, velocity: 0.01);
final spring =
    SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: 1);

double snapTargetFor(double position, double velocity) {
  final coasted = position + carouselCoastingDistance(velocity, tolerance);
  final item = (coasted / itemExtent).round();
  return (velocity > 0
          ? max(item, (position / itemExtent).floor() + 1)
          : min(item, (position / itemExtent).ceil() - 1)) *
      itemExtent;
}

Simulation flingFrom(double position, double velocity) =>
    carouselSnapSimulation(
      position: position,
      velocity: velocity,
      target: snapTargetFor(position, velocity),
      spring: spring,
      tolerance: tolerance,
    );

void main() {
  final flings = {
    'short flick': (position: 0.0, velocity: 1000.0),
    'hard flick': (position: 0.0, velocity: 4000.0),
    'very hard flick': (position: 0.0, velocity: 8000.0),
    'barely moving release': (position: 100.0, velocity: 20.0),
    'slow flick that stops short': (position: 50.0, velocity: 300.0),
    'flick from mid-item': (position: 700.0, velocity: 2500.0),
    'flick backward': (position: 600.0, velocity: -1500.0),
    'hard flick backward': (position: 2000.0, velocity: -4000.0),
    'flick that coasts past the nearest item': (
      position: 130.0,
      velocity: 1300.0
    ),
  };

  group('carouselSnapSimulation', () {
    for (final entry in flings.entries) {
      final fling = entry.value;
      final simulation = flingFrom(fling.position, fling.velocity);
      final target = snapTargetFor(fling.position, fling.velocity);

      test('${entry.key} starts where the finger left off', () {
        expect(simulation.x(0), closeTo(fling.position, 0.001));
        expect(simulation.dx(0), closeTo(fling.velocity, 0.001));
      });

      test('${entry.key} comes to rest on an item', () {
        expect(target % itemExtent, 0);

        var time = 0.0;
        while (!simulation.isDone(time) && time < 10) {
          time += 0.001;
        }

        expect(simulation.isDone(time), isTrue);
        expect(simulation.x(time), closeTo(target, 0.5));
      });

      test('${entry.key} never overshoots or reverses', () {
        final direction = (target - fling.position).sign;
        var previous = fling.position;

        for (var time = 0.0; time <= 3; time += 0.001) {
          final position = simulation.x(time);

          expect((position - previous) * direction, greaterThanOrEqualTo(-0.01),
              reason: 'reversed at $time s');
          expect((position - target) * direction, lessThan(0.01),
              reason: 'overshot at $time s');
          previous = position;
        }
      });
    }

    test('a harder flick coasts farther', () {
      expect(carouselCoastingDistance(4000, tolerance),
          greaterThan(carouselCoastingDistance(1500, tolerance)));
    });

    test('a flick backward coasts backward', () {
      expect(carouselCoastingDistance(-2500, tolerance), lessThan(0));
    });
  });
}
