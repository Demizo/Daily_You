import 'package:daily_you/storage/external_sync_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ExternalSyncHealth health;

  setUp(() => health = ExternalSyncHealth('test'));

  test('has no attempt before anything is written', () {
    expect(health.lastAttempt, isNull);
    expect(health.isStale, isFalse);
  });

  test('records a successful write', () async {
    expect(await health.record('write', () async => true), isTrue);

    expect(health.lastAttempt!.succeeded, isTrue);
    expect(health.lastAttempt!.failureReason, isNull);
    expect(health.isStale, isFalse);
  });

  test('records a rejected write with a reason', () async {
    expect(await health.record('write', () async => false), isFalse);

    expect(health.lastAttempt!.succeeded, isFalse);
    expect(health.lastAttempt!.failureReason, contains('write'));
    expect(health.isStale, isTrue);
  });

  test('records a thrown failure instead of rethrowing', () async {
    expect(
        await health.record('write', () async => throw Exception('no access')),
        isFalse);

    expect(health.lastAttempt!.succeeded, isFalse);
    expect(health.lastAttempt!.failureReason, contains('no access'));
  });

  test('a later success clears the stale state', () async {
    await health.record('write', () async => false);
    await health.record('write', () async => true);

    expect(health.isStale, isFalse);
  });
}
