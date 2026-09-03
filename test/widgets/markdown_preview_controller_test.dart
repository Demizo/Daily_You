import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the scan is reused until the text changes', () {
    final controller = MarkdownPreviewController(text: '**loud**');
    addTearDown(controller.dispose);

    expect(controller.scan, same(controller.scan));

    final first = controller.scan;
    controller.text = '**loud** and clear';
    expect(controller.scan, isNot(same(first)));
  });

  test('misspellings move with edits made after the check', () {
    final controller = MarkdownPreviewController(text: 'hello wrng there');
    addTearDown(controller.dispose);
    controller.receiveSpellCheck('hello wrng there', [
      const SuggestionSpan(TextRange(start: 6, end: 10), ['wrong']),
    ]);

    controller.text = 'well hello wrng there';
    expect(controller.misspellings.single.range,
        const TextRange(start: 11, end: 15));

    controller.text = 'hello wrong there';
    expect(controller.misspellings, isEmpty);
  });
}
