// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:flutter/widgets.dart';

const _platformFriction = 0.015;
const _snappingFriction = 0.05;
const _maximumFriction = 1000.0;
const _frictionSearchSteps = 60;

double _coastingDistance(
        double velocity, double friction, Tolerance tolerance) =>
    ClampingScrollSimulation(
      position: 0,
      velocity: velocity,
      friction: friction,
      tolerance: tolerance,
    ).x(double.infinity);

double carouselCoastingDistance(double velocity, Tolerance tolerance) =>
    _coastingDistance(velocity, _snappingFriction, tolerance);

double _frictionToCoast({
  required double velocity,
  required double distance,
  required Tolerance tolerance,
}) {
  var lowLogFriction = log(_platformFriction);
  var highLogFriction = log(_maximumFriction);
  for (var step = 0; step < _frictionSearchSteps; step++) {
    final middle = (lowLogFriction + highLogFriction) / 2;
    if (_coastingDistance(velocity, exp(middle), tolerance) > distance) {
      lowLogFriction = middle;
    } else {
      highLogFriction = middle;
    }
  }
  return exp(highLogFriction);
}

Simulation carouselSnapSimulation({
  required double position,
  required double velocity,
  required double target,
  required SpringDescription spring,
  required Tolerance tolerance,
}) {
  final distance = target - position;
  final movesTowardTarget = velocity * distance > 0;
  final canCoastToTarget = movesTowardTarget &&
      _coastingDistance(velocity.abs(), _platformFriction, tolerance) >=
          distance.abs();
  if (!canCoastToTarget) {
    return ScrollSpringSimulation(spring, position, target, velocity,
        tolerance: tolerance);
  }
  return ClampingScrollSimulation(
    position: position,
    velocity: velocity,
    friction: _frictionToCoast(
      velocity: velocity.abs(),
      distance: distance.abs(),
      tolerance: tolerance,
    ),
    tolerance: tolerance,
  );
}
