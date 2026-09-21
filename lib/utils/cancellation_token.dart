import 'dart:isolate';

class BackupCancelledException implements Exception {}

/// Kills the attached [Isolate] on cancel, not just between awaited steps.
class CancellationToken {
  bool _isCancelled = false;
  Isolate? _isolate;
  void Function()? _onCancelled;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
    _onCancelled?.call();
  }

  void attachIsolate(Isolate isolate, void Function() onCancelled) {
    if (_isCancelled) {
      isolate.kill(priority: Isolate.immediate);
      onCancelled();
      return;
    }
    _isolate = isolate;
    _onCancelled = onCancelled;
  }

  void detach() {
    _isolate = null;
    _onCancelled = null;
  }
}
