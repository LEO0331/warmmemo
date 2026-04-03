class RequestPolicy {
  const RequestPolicy({
    this.ttl = const Duration(seconds: 30),
    this.debounce = const Duration(milliseconds: 350),
    this.retryCount = 2,
    this.backoffBase = const Duration(milliseconds: 250),
  });

  final Duration ttl;
  final Duration debounce;
  final int retryCount;
  final Duration backoffBase;
}
