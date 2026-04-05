import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/data/app_failure.dart';
import 'package:warmmemo/core/data/app_policies.dart';
import 'package:warmmemo/core/data/debouncer.dart';
import 'package:warmmemo/core/data/memory_cache_store.dart';
import 'package:warmmemo/core/data/optimistic_mutation.dart';
import 'package:warmmemo/core/data/request_policy.dart';
import 'package:warmmemo/core/data/retry.dart';
import 'package:warmmemo/core/data/view_state.dart';

void main() {
  group('core/data - AppFailure', () {
    test('maps permission/network/validation/unknown', () {
      expect(
        AppFailure.from(StateError('permission-denied')).runtimeType,
        PermissionFailure,
      );
      expect(
        AppFailure.from(StateError('socket unavailable')).runtimeType,
        NetworkFailure,
      );
      expect(
        AppFailure.from(StateError('invalid payload')).runtimeType,
        ValidationFailure,
      );
      expect(
        AppFailure.from(StateError('something else')).runtimeType,
        UnknownFailure,
      );
    });
  });

  group('core/data - RequestPolicy & AppPolicies', () {
    test('default request policy follows app policies', () {
      const policy = RequestPolicy();
      expect(policy.ttl, AppPolicies.cacheTtl);
      expect(policy.debounce, AppPolicies.debounce);
      expect(policy.retryCount, AppPolicies.retryCount);
      expect(policy.backoffBase, AppPolicies.backoffBase);
    });

    test('supports custom policy', () {
      const policy = RequestPolicy(
        ttl: Duration(seconds: 5),
        debounce: Duration(milliseconds: 99),
        retryCount: 1,
        backoffBase: Duration(milliseconds: 10),
      );
      expect(policy.ttl.inSeconds, 5);
      expect(policy.debounce.inMilliseconds, 99);
      expect(policy.retryCount, 1);
      expect(policy.backoffBase.inMilliseconds, 10);
    });
  });

  group('core/data - MemoryCacheStore', () {
    test('set/get/hasValid/invalidate/clear', () {
      final cache = MemoryCacheStore<String, int>();
      cache.set('a', 1, ttl: const Duration(seconds: 1));
      expect(cache.get('a'), 1);
      expect(cache.hasValid('a'), isTrue);
      cache.invalidate('a');
      expect(cache.get('a'), isNull);
      cache.set('b', 2);
      cache.clear();
      expect(cache.get('b'), isNull);
    });

    test('expires by ttl', () async {
      final cache = MemoryCacheStore<String, int>();
      cache.set('a', 1, ttl: const Duration(milliseconds: 20));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(cache.get('a'), isNull);
      expect(cache.hasValid('a'), isFalse);
    });
  });

  group('core/data - Debouncer', () {
    test('only runs latest action within delay', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 30));
      var count = 0;
      debouncer.run(() => count += 1);
      debouncer.run(() => count += 10);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(count, 10);
      debouncer.dispose();
    });
  });

  group('core/data - Retry & optimistic/value objects', () {
    test('withRetry retries until success', () async {
      var attempt = 0;
      final result = await withRetry(
        () async {
          attempt += 1;
          if (attempt < 3) throw StateError('temporary');
          return 'ok';
        },
        policy: const RequestPolicy(
          retryCount: 3,
          backoffBase: Duration(milliseconds: 1),
        ),
      );
      expect(result, 'ok');
      expect(attempt, 3);
    });

    test('withRetry respects canRetry=false', () async {
      var attempt = 0;
      expect(
        () => withRetry(
          () async {
            attempt += 1;
            throw StateError('stop');
          },
          policy: const RequestPolicy(
            retryCount: 3,
            backoffBase: Duration(milliseconds: 1),
          ),
          canRetry: (_) => false,
        ),
        throwsA(isA<StateError>()),
      );
      expect(attempt, 1);
    });

    test('optimistic mutation and view states are constructible', () {
      const idle = IdleState();
      const loading = LoadingState();
      const success = SuccessState(message: 'done');
      const error = ErrorState('fail');
      final mutation = OptimisticMutation<int>(
        previous: 1,
        optimistic: 2,
        committed: 3,
      );

      expect(idle, isA<ViewState>());
      expect(loading, isA<ViewState>());
      expect(success.message, 'done');
      expect(error.message, 'fail');
      expect(mutation.previous, 1);
      expect(mutation.optimistic, 2);
      expect(mutation.committed, 3);
    });
  });
}
