import 'dart:isolate';

class BackupCancelledException implements Exception {}

/// Kills the attached [Isolate]s on cancel, not just between awaited steps.
class CancellationToken {
  bool _isCancelled = false;
  final Set<Isolate> _isolates = {};
  void Function()? _onCancelled;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final isolate in _isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
    _onCancelled?.call();
  }

  void attachIsolate(Isolate isolate, void Function() onCancelled) {
    attachIsolates([isolate], onCancelled);
  }

  /// Same as [attachIsolate], but for a batch of isolates working in parallel
  /// on one operation, so cancelling kills all of them together.
  void attachIsolates(Iterable<Isolate> isolates, void Function() onCancelled) {
    if (_isCancelled) {
      for (final isolate in isolates) {
        isolate.kill(priority: Isolate.immediate);
      }
      onCancelled();
      return;
    }
    _isolates.addAll(isolates);
    _onCancelled = onCancelled;
  }

  void detach() {
    _isolates.clear();
    _onCancelled = null;
  }
}
