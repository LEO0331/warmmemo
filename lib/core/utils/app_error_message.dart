import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/app_failure.dart';

String appErrorMessage(Object error, {required String fallback}) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return '權限不足，請確認帳號角色或 Firestore 規則。';
    }
    if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
      return '網路暫時不穩，請稍後再試。';
    }
    return error.message ?? fallback;
  }
  return AppFailure.from(error).message;
}
