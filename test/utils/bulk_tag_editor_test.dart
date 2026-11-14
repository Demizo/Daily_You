// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/bulk_tag_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const none = 1, some = 2, all = 3;

  BulkTagEditor editor(TagChange change) => BulkTagEditor(change, 2,
      {some: TagPresence.some, all: TagPresence.all, none: TagPresence.none});

  test('adding applies to tags missing from at least one log', () {
    final tagEditor = editor(TagChange.add);
    expect(tagEditor.isApplicable(none), isTrue);
    expect(tagEditor.isApplicable(some), isTrue);
    expect(tagEditor.isApplicable(all), isFalse);
    expect(tagEditor.isApplicable(99), isTrue);
  });

  test('removing applies to tags on at least one log', () {
    final tagEditor = editor(TagChange.remove);
    expect(tagEditor.isApplicable(none), isFalse);
    expect(tagEditor.isApplicable(some), isTrue);
    expect(tagEditor.isApplicable(all), isTrue);
    expect(tagEditor.isApplicable(99), isFalse);
  });

  test('toggling chooses a tag for adding and then unchooses it', () {
    final tagEditor = editor(TagChange.add);
    expect(tagEditor.hasChanges, isFalse);

    tagEditor.toggle(some, value: '3');
    expect(tagEditor.isChosen(some), isTrue);
    expect(tagEditor.chosenTagIds, [some]);
    expect(tagEditor.additions, {some: '3'});
    expect(tagEditor.removals, isEmpty);

    tagEditor.toggle(some);
    expect(tagEditor.hasChanges, isFalse);
  });

  test('toggling chooses a tag for removing and drops any value', () {
    final tagEditor = editor(TagChange.remove);
    tagEditor.toggle(all, value: '9');
    expect(tagEditor.removals, {all});
    expect(tagEditor.additions, isEmpty);
    expect(tagEditor.valueOf(all), isNull);
  });

  test('ignores a tag the change cannot apply to', () {
    final adding = editor(TagChange.add)..toggle(all);
    final removing = editor(TagChange.remove)..toggle(none);
    expect(adding.hasChanges, isFalse);
    expect(removing.hasChanges, isFalse);
  });

  test('notifies on every toggle', () {
    final tagEditor = editor(TagChange.add);
    var notifications = 0;
    tagEditor.addListener(() => notifications += 1);
    tagEditor.toggle(none);
    tagEditor.toggle(none);
    expect(notifications, 2);
  });
}
