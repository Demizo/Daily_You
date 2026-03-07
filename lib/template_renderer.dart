import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

class TemplateVariable {
  final String value;
  final String label;
  TemplateVariable(this.value, this.label);
}

class TemplateRenderer {
  static final RegExp _variablePattern = RegExp(r"\{\{(\w+)(?::([^}]+))?\}\}");

  /// Populates template variables: {{date}}, {{time}}
  /// Variables can have optional formatting like so, {{date:yyyy-MM-dd}} or {{time:HH:mm}}
  static String populate(BuildContext context, String template) {
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();

    return template.replaceAllMapped(_variablePattern, (match) {
      final variable = match.group(1);
      final format = match.group(2);

      switch (variable) {
        case "date":
          return _formatDate(now, locale, format);

        case "time":
          return _formatTime(now, locale, format);

        default:
          return match.group(0)!; // leave unknown variables unchanged
      }
    });
  }

  static List<TemplateVariable> getVariableList(BuildContext context) {
    return [
      TemplateVariable('{{date}}', AppLocalizations.of(context)!.sortDateTitle),
      TemplateVariable(
          '{{time}}', AppLocalizations.of(context)!.templateVariableTime),
    ];
  }

  static String _formatDate(DateTime dt, Locale locale, String? format) {
    try {
      if (format != null && format.isNotEmpty) {
        return DateFormat(format, locale.toString()).format(dt);
      }
    } catch (_) {
      // Do nothing
    }

    return DateFormat.yMd(locale.toString()).format(dt);
  }

  static String _formatTime(DateTime dt, Locale locale, String? format) {
    try {
      if (format != null && format.isNotEmpty) {
        return DateFormat(format, locale.toString()).format(dt);
      }
    } catch (_) {
      // Do nothing
    }

    return DateFormat.jm(locale.toString()).format(dt);
  }
}
