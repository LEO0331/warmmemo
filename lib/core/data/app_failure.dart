sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;

  static AppFailure from(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('permission-denied') || text.contains('unauthorized')) {
      return PermissionFailure('權限不足，請確認帳號角色或登入狀態。', cause: error);
    }
    if (text.contains('timeout') ||
        text.contains('network') ||
        text.contains('socket') ||
        text.contains('unavailable')) {
      return NetworkFailure('網路不穩或服務暫時無法連線，請稍後重試。', cause: error);
    }
    if (text.contains('validation') || text.contains('invalid')) {
      return ValidationFailure('資料格式不正確，請檢查後再送出。', cause: error);
    }
    return UnknownFailure('發生未預期錯誤，請稍後重試。', cause: error);
  }
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause});
}

class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message, {super.cause});
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause});
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause});
}
