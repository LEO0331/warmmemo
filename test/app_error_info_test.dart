import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/utils/app_error_info.dart';

void main() {
  group('appErrorInfo', () {
    test('maps firebase error code and safe message', () {
      final info = appErrorInfo(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        fallback: 'fallback',
      );
      expect(info.code, 'permission-denied');
      expect(info.message, contains('權限不足'));
    });

    test('maps hosted payment-link errors', () {
      final info = appErrorInfo(
        StateError('Bad state: payment-link-missing:STRIPE_PAYMENT_LINK_120000'),
        fallback: 'fallback',
      );
      expect(info.code, contains('payment-link-missing'));
      expect(info.message, contains('付款連結'));
    });

    test('extracts request id from raw text when present', () {
      final info = appErrorInfo(
        StateError('failed-precondition requestId=req_abc_123'),
        fallback: 'fallback',
      );
      expect(info.requestId, 'req_abc_123');
    });
  });
}
