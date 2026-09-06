import 'package:logging/logging.dart';

class ExternalSyncAttempt {
  const ExternalSyncAttempt({
    required this.time,
    required this.succeeded,
    this.failureReason,
  });

  final DateTime time;
  final bool succeeded;
  final String? failureReason;
}

/// Record and log external sync outcomes
class ExternalSyncHealth {
  ExternalSyncHealth(String loggerName) : _logger = Logger(loggerName);

  final Logger _logger;

  ExternalSyncAttempt? _lastAttempt;
  ExternalSyncAttempt? get lastAttempt => _lastAttempt;

  bool get isStale => _lastAttempt?.succeeded == false;

  Future<bool> record(String operation, Future<bool> Function() write) async {
    try {
      final succeeded = await write();
      if (succeeded) {
        _lastAttempt =
            ExternalSyncAttempt(time: DateTime.now(), succeeded: true);
      } else {
        _fail("$operation was rejected");
      }
      return succeeded;
    } catch (error) {
      _fail("$operation failed: $error");
      return false;
    }
  }

  void _fail(String reason) {
    _lastAttempt = ExternalSyncAttempt(
        time: DateTime.now(), succeeded: false, failureReason: reason);
    _logger.severe(reason);
  }
}
