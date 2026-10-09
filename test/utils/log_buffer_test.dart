// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/utils/logging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogBuffer', () {
    setUp(() {
      LogBuffer.clear();
    });

    test('buffers log entries and clears', () {
      expect(LogBuffer.logs, isEmpty);

      LogBuffer.add('entry 1');
      LogBuffer.add('entry 2');

      expect(LogBuffer.logs.length, 2);
      expect(LogBuffer.logs[0], 'entry 1');
      expect(LogBuffer.logs[1], 'entry 2');

      LogBuffer.clear();
      expect(LogBuffer.logs, isEmpty);
    });

    test('caps buffer size at maxBufferSize', () {
      for (var i = 0; i < LogBuffer.maxBufferSize + 10; i++) {
        LogBuffer.add('entry $i');
      }

      expect(LogBuffer.logs.length, LogBuffer.maxBufferSize);
      expect(LogBuffer.logs.first, 'entry 10');
      expect(LogBuffer.logs.last, 'entry ${LogBuffer.maxBufferSize + 9}');
    });
  });
}
