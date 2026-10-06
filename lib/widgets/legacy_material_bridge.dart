import 'package:daily_you/custom_locale_delegates.dart';
import 'package:material_ui/material_ui.dart';

/// Legacy theme bridge with corrected icon colors
class LegacyMaterialBridge extends StatelessWidget {
  final Widget child;

  const LegacyMaterialBridge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modernIconTheme = theme.iconTheme.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // ignore: deprecated_member_use
    return MaterialUiCompatibilityBridge(
      delegates: sdkLocalizationsDelegates,
      child: IconTheme(data: modernIconTheme, child: child),
    );
  }
}
