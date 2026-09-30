import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddEditEntryPage.mergeSharedText', () {
    test('returns the base text unchanged when there is no shared text', () {
      expect(AddEditEntryPage.mergeSharedText('template text', null),
          'template text');
      expect(AddEditEntryPage.mergeSharedText('', null), '');
    });

    test('uses the shared text alone when the base text is empty', () {
      expect(AddEditEntryPage.mergeSharedText('', 'shared'), 'shared');
    });

    test('appends the shared text as a new paragraph after existing text', () {
      expect(AddEditEntryPage.mergeSharedText('template text', 'shared'),
          'template text\n\nshared');
    });
  });
}
