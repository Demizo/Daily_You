// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

/// How a chart should combine the values within a single time bucket.
typedef BucketCombiner = double Function(List<double> bucketValues);

double combineByAverage(List<double> bucketValues) =>
    bucketValues.reduce((a, b) => a + b) / bucketValues.length;

double combineBySum(List<double> bucketValues) =>
    bucketValues.reduce((a, b) => a + b);
