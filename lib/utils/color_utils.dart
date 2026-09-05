import 'package:flutter/material.dart';

Color contrastingTextColor(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
