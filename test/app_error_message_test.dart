import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/utils/app_error_message.dart';

void main() {
  group('appErrorMessage', () {
    test('maps permission denied', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      final message = appErrorMessage(error, fallback: 'fallback');
      expect(message, contains('權限不足'));
    });

    test('maps unavailable network-like error', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      final message = appErrorMessage(error, fallback: 'fallback');
      expect(message, contains('網路'));
    });

    test('falls back to firebase message and generic mapping', () {
      final firebaseError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'index missing',
      );
      expect(
        appErrorMessage(firebaseError, fallback: 'fallback'),
        'index missing',
      );
      expect(
        appErrorMessage(StateError('validation failed'), fallback: 'fallback'),
        contains('資料格式不正確'),
      );
    });
  });
}
