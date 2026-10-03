import 'package:material_ui/material_ui.dart';

Color contrastingTextColor(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
