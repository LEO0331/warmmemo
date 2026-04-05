import 'dart:async';

import 'request_policy.dart';

Future<T> withRetry<T>(
  Future<T> Function() task, {
  RequestPolicy policy = const RequestPolicy(),
  bool Function(Object error)? canRetry,
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await task();
    } catch (error) {
      final allowed = canRetry?.call(error) ?? true;
      if (!allowed || attempt >= policy.retryCount) rethrow;
      final wait = policy.backoffBase * (attempt + 1);
      await Future<void>.delayed(wait);
      attempt += 1;
    }
  }
}
