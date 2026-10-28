// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class SettingsPageScaffold extends StatelessWidget {
  SettingsPageScaffold({
    super.key,
    required this.title,
    this.actions = const [],
    this.floatingActionButton,
    required List<Widget> children,
  }) : _body = SettingsListView(children: children);

  SettingsPageScaffold.slivers({
    super.key,
    required this.title,
    this.actions = const [],
    this.floatingActionButton,
    required List<Widget> slivers,
  }) : _body = SettingsListView.slivers(slivers: slivers);

  final String title;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget _body;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surface;
    final inPane = SettingsPane.contains(context);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: inPane ? null : Text(title),
        centerTitle: true,
        automaticallyImplyLeading: !inPane,
        backgroundColor: background,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: _body,
    );
  }
}

class SettingsListView extends StatelessWidget {
  const SettingsListView({super.key, required List<Widget> children})
      : _children = children,
        _slivers = null;

  const SettingsListView.slivers({super.key, required List<Widget> slivers})
      : _slivers = slivers,
        _children = null;

  final List<Widget>? _children;
  final List<Widget>? _slivers;

  static const double maxWidth = 760;

  @override
  Widget build(BuildContext context) {
    final children = _children;
    final hasFloatingActionButton =
        Scaffold.maybeOf(context)?.hasFloatingActionButton ?? false;
    final bottom = MediaQuery.paddingOf(context).bottom +
        (hasFloatingActionButton ? 96 : 24);
    return LayoutBuilder(builder: (context, constraints) {
      final inset =
          16 + math.max<double>(0, (constraints.maxWidth - maxWidth) / 2);
      return CustomScrollView(slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(inset, 8, inset, bottom),
          sliver: children == null
              ? SliverMainAxisGroup(slivers: _slivers!)
              : SliverList.list(children: [
                  for (var index = 0; index < children.length; index++) ...[
                    if (index > 0) const SizedBox(height: 16),
                    children[index],
                  ],
                ]),
        ),
      ]);
    });
  }
}

class SettingsPane extends InheritedWidget {
  const SettingsPane({super.key, required super.child});

  static bool contains(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsPane>() != null;

  @override
  bool updateShouldNotify(SettingsPane oldWidget) => false;
}
