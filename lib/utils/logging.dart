// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class LogBuffer {
  static const int maxBufferSize = 500;
  static final List<String> _logs = [];
  static final ValueNotifier<int> logChangeNotifier = ValueNotifier<int>(0);

  static List<String> get logs => List.unmodifiable(_logs);

  static void add(String entry) {
    if (_logs.length >= maxBufferSize) {
      _logs.removeAt(0);
    }
    _logs.add(entry);
    logChangeNotifier.value++;
  }

  static void clear() {
    _logs.clear();
    logChangeNotifier.value++;
  }
}

void configureLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  final timeFormatter = DateFormat('HH:mm:ss.SSS');

  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer(
        '${record.level.name} ${record.loggerName}: ${record.message}');
    if (record.error != null) buffer.write(' | ${record.error}');
    if (record.stackTrace != null) buffer.write('\n${record.stackTrace}');
    final logText = buffer.toString();
    debugPrint(logText);

    final isDiagnosticEnabled =
        ConfigProvider.instance.get(Settings.diagnosticLoggingEnabled);
    if (kDebugMode || isDiagnosticEnabled) {
      final timestamp = timeFormatter.format(record.time);
      LogBuffer.add('[$timestamp] $logText');
    }
  });
}
