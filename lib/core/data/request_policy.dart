import 'app_policies.dart';

class RequestPolicy {
  const RequestPolicy({
    this.ttl = AppPolicies.cacheTtl,
    this.debounce = AppPolicies.debounce,
    this.retryCount = AppPolicies.retryCount,
    this.backoffBase = AppPolicies.backoffBase,
  });

  final Duration ttl;
  final Duration debounce;
  final int retryCount;
  final Duration backoffBase;
}
