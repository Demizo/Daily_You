// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

const double chartBarGap = 6;
const double chartMaximumBarWidth = 32;
const double _chartMinimumBarWidth = 4;

double chartBarWidth({required double plotWidth, required int barCount}) =>
    math.max(
      _chartMinimumBarWidth,
      math.min(chartMaximumBarWidth, plotWidth / barCount - chartBarGap),
    );
