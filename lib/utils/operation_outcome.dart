enum OperationStatus { succeeded, cancelled, failed }

class OperationOutcome {
  const OperationOutcome.succeeded()
      : status = OperationStatus.succeeded,
        error = null;

  const OperationOutcome.cancelled()
      : status = OperationStatus.cancelled,
        error = null;

  const OperationOutcome.failed([this.error]) : status = OperationStatus.failed;

  final OperationStatus status;
  final Object? error;

  bool get succeeded => status == OperationStatus.succeeded;
  bool get failed => status == OperationStatus.failed;
}
