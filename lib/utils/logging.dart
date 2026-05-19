import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

void configureLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer(
        '${record.level.name} ${record.loggerName}: ${record.message}');
    if (record.error != null) buffer.write(' | ${record.error}');
    if (record.stackTrace != null) buffer.write('\n${record.stackTrace}');
    debugPrint(buffer.toString());
  });
}
