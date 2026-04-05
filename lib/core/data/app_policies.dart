class AppPolicies {
  static const cacheTtl = Duration(seconds: 30);
  static const debounce = Duration(milliseconds: 350);
  static const retryCount = 2;
  static const backoffBase = Duration(milliseconds: 250);
}
