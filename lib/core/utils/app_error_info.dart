import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppErrorInfo {
  const AppErrorInfo({
    required this.code,
    required this.message,
    this.requestId,
    this.rawDebug,
  });

  final String code;
  final String message;
  final String? requestId;
  final String? rawDebug;
}

AppErrorInfo appErrorInfo(
  Object error, {
  required String fallback,
}) {
  final raw = error.toString();
  final code = _extractCode(error, raw);
  final message = _safeMessage(code, fallback: fallback);
  final requestId = _extractRequestId(raw);
  return AppErrorInfo(
    code: code,
    message: message,
    requestId: requestId,
    rawDebug: kDebugMode ? raw : null,
  );
}

void logDebugError(String tag, Object error) {
  if (!kDebugMode) return;
  debugPrint('[AppError][$tag] $error');
}

String _extractCode(Object error, String raw) {
  if (error is FirebaseException && error.code.isNotEmpty) {
    return error.code;
  }
  if (raw.contains('payment-link-missing:')) {
    final key = raw.split('payment-link-missing:').last.trim();
    return 'payment-link-missing${key.isEmpty ? '' : ' ($key)'}';
  }
  if (raw.contains('payment-link-missing')) return 'payment-link-missing';
  if (raw.contains('payment-link-invalid')) return 'payment-link-invalid';
  if (raw.contains('workflow-invalid-transition')) {
    return 'workflow-invalid-transition';
  }
  final match = RegExp(r'\[([^\]]+)\]').firstMatch(raw);
  if (match == null) return 'unknown';
  final bracket = match.group(1) ?? 'unknown';
  if (bracket.contains('/')) return bracket.split('/').last;
  return bracket;
}

String _safeMessage(String code, {required String fallback}) {
  if (code.startsWith('payment-link-missing')) {
    return '付款連結設定不完整，請補齊對應方案連結。';
  }
  switch (code) {
    case 'permission-denied':
      return '權限不足，請確認帳號角色與 Firestore 規則。';
    case 'failed-precondition':
      return '缺少必要前置設定（通常是索引或規則條件）。';
    case 'unavailable':
    case 'deadline-exceeded':
      return '服務暫時不可用，請稍後再試。';
    case 'payment-link-invalid':
      return '付款連結設定不完整或格式錯誤。';
    case 'workflow-invalid-transition':
      return '訂單狀態流轉不合法，請依既定流程更新。';
    default:
      return fallback;
  }
}

String? _extractRequestId(String raw) {
  final match = RegExp(
    r'(request[_\s-]?id|req[_\s-]?id)\s*[:=]\s*([A-Za-z0-9._:-]+)',
    caseSensitive: false,
  ).firstMatch(raw);
  return match?.group(2);
}
