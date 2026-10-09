// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/utils/text_editing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Editor Actions (F10)', () {
    test('toggleChecklist cycles from plain to unchecked to checked to plain', () {
      final controller = TextEditingController(text: 'My task');

      // 1. Plain -> Unchecked
      toggleChecklist(controller);
      expect(controller.text, '- [ ] My task');

      // 2. Unchecked -> Checked
      toggleChecklist(controller);
      expect(controller.text, '- [x] My task');

      // 3. Checked -> Plain
      toggleChecklist(controller);
      expect(controller.text, 'My task');
    });

    test('toggleChecklist converts bullet list line to checklist', () {
      final controller = TextEditingController(text: '- Bullet item');
      toggleChecklist(controller);
      expect(controller.text, '- [ ] Bullet item');
    });

    test('indentLine indents and outdents lines correctly', () {
      final controller = TextEditingController(text: 'Hello');

      // Indent
      indentLine(controller, outdent: false);
      expect(controller.text, '  Hello');

      indentLine(controller, outdent: false);
      expect(controller.text, '    Hello');

      // Outdent
      indentLine(controller, outdent: true);
      expect(controller.text, '  Hello');

      indentLine(controller, outdent: true);
      expect(controller.text, 'Hello');
    });
  });
}
