import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/utils/input_guard.dart';

void main() {
  group('InputGuard', () {
    test('singleLine removes control chars and clamps length', () {
      final result = InputGuard.singleLine('A\tB\r\n<C>\u0001', maxLength: 6);
      expect(result, 'A B ＜C');
    });

    test('multiline normalizes newlines and clamps', () {
      final result = InputGuard.multiline(
        'line1\r\n\r\n\r\nline2<ok>',
        maxLength: 20,
      );
      expect(result, 'line1\n\nline2＜ok＞');
    });

    test('multiline applies truncation branch', () {
      final result = InputGuard.multiline('12345678901234567890', maxLength: 8);
      expect(result, '12345678');
    });

    test('dateOrText normalizes valid yyyy/mm/dd', () {
      final result = InputGuard.dateOrText('2026/4/5', maxLength: 20);
      expect(result, '2026-04-05');
    });

    test('dateOrText keeps open text when not a date', () {
      final result = InputGuard.dateOrText('下月前完成', maxLength: 20);
      expect(result, '下月前完成');
    });

    test('dateOrText normalizes year-month branch', () {
      final result = InputGuard.dateOrText('2026-4', maxLength: 20);
      expect(result, '2026-04');
    });

    test('boundedInt and boundedAmount enforce range', () {
      expect(InputGuard.boundedInt('999', fallback: 10, min: 0, max: 130), 130);
      expect(InputGuard.boundedAmount('-20'), 0);
      expect(InputGuard.boundedAmount('abc'), 0);
    });
  });
}
