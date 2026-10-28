// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:material_ui/material_ui.dart';

Widget? _icon(IconData? icon) => icon == null ? null : Icon(icon);

Widget? _text(String? text) => text == null ? null : Text(text);

class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      leading: _icon(icon),
      title: Text(title),
      subtitle: _text(subtitle),
      iconColor: color,
      textColor: color,
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.onOpenOptions,
  });

  SettingsToggleRow.setting({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required Setting<bool> setting,
  })  : value = ConfigProvider.instance.get(setting),
        onChanged = ((value) => ConfigProvider.instance.set(setting, value)),
        onOpenOptions = null;

  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onOpenOptions;

  @override
  Widget build(BuildContext context) {
    if (onOpenOptions == null) {
      return SwitchListTile(
        secondary: _icon(icon),
        title: Text(title),
        subtitle: _text(subtitle),
        value: value,
        onChanged: onChanged,
      );
    }
    return ListTile(
      leading: _icon(icon),
      title: Text(title),
      subtitle: _text(subtitle),
      enabled: onChanged != null,
      onTap: value ? onOpenOptions : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          if (value)
            const SizedBox(
              height: 32,
              child: VerticalDivider(width: 1, thickness: 1),
            ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class SettingsChoiceRow<T> extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.accessoryBuilder,
  });

  final IconData? icon;
  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final Widget? Function(T option)? accessoryBuilder;

  Widget? _labelOf(T option) {
    final label = _text(options[option]);
    final accessory = accessoryBuilder?.call(option);
    if (label == null || accessory == null) return label;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [label, accessory],
    );
  }

  Future<void> _choose(BuildContext context) {
    return showSettingsDialog(
      context: context,
      isSelection: true,
      builder: (context) {
        void select(T option) {
          Navigator.of(context).pop();
          onChanged(option);
        }

        return [
          RadioGroup<T>(
            groupValue: value,
            onChanged: (option) => select(option as T),
            child: Column(children: [
              for (final option in options.keys)
                MergeSemantics(
                  child: ListTile(
                    leading: ExcludeFocus(
                      child: IgnorePointer(
                        child: Radio<T>(
                          value: option,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(
                            horizontal: VisualDensity.minimumDensity,
                            vertical: VisualDensity.minimumDensity,
                          ),
                        ),
                      ),
                    ),
                    title: _labelOf(option),
                    onTap: () => select(option),
                  ),
                ),
            ]),
          ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _icon(icon),
      title: Text(title),
      subtitle: _labelOf(value),
      onTap: () => _choose(context),
    );
  }
}

class SettingsDependents extends StatelessWidget {
  const SettingsDependents({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: ExcludeFocus(
        excluding: !enabled,
        child: Opacity(opacity: enabled ? 1 : 0.38, child: child),
      ),
    );
  }
}

class SettingsDialogRow extends StatelessWidget {
  const SettingsDialogRow({
    super.key,
    this.icon,
    required this.title,
    required this.options,
  });

  final IconData? icon;
  final String title;
  final SettingsRowsBuilder options;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _icon(icon),
      title: Text(title),
      onTap: () => showSettingsDialog(context: context, builder: options),
    );
  }
}

class SettingsInfoRow extends StatelessWidget {
  const SettingsInfoRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.value,
  });

  final IconData? icon;
  final String title;
  final Widget? subtitle;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _icon(icon),
      title: Text(title),
      subtitle: subtitle,
      trailing: _text(value),
      leadingAndTrailingTextStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
