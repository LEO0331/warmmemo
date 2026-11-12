import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/features/final_countdown/financial_footing_model.dart';

void main() {
  group('financial footing input', () {
    test('keeps blank, explicit zero, and valid decimals distinct', () {
      expect(parseFinancialFootingInput('  '), (value: null, isInvalid: false));
      expect(parseFinancialFootingInput('0'), (value: 0.0, isInvalid: false));
      expect(parseFinancialFootingInput(' 12,345.67 '), (
        value: 12345.67,
        isInvalid: false,
      ));
      expect(parseFinancialFootingInput('.5'), (value: 0.5, isInvalid: false));
      expect(
        parseFinancialFootingInput('999,999,999,999.00').value,
        maxFinancialFootingInput,
      );
    });

    test('rejects invalid amounts without silently changing them', () {
      for (final input in [
        '-20',
        '-0',
        'NaN',
        'Infinity',
        '1e309',
        '999999999999.01',
        '1000000000000',
        '12,34',
        '1.001',
        '1 000',
        '1\n000',
      ]) {
        expect(parseFinancialFootingInput(input), (
          value: null,
          isInvalid: true,
        ), reason: input);
      }
    });
  });

  group('financial footing snapshot', () {
    test('uses current assets and liabilities to calculate net worth', () {
      final snapshot = FinancialFootingSnapshot(
        liquidCash: 90000.25,
        investments: 250000.50,
        nonLiquidAssets: 1600000.75,
        liabilities: 500000.25,
        monthlyEssentials: 30000,
      );
      expect(snapshot.estimatedNetWorth, 1440001.25);
      expect(snapshot.cashBufferMonths, 90000.25 / 30000);
      expect(snapshot.bufferStatus, FinancialBufferStatus.noTarget);
    });

    test('permits negative net worth and explicit zero balances', () {
      expect(
        FinancialFootingSnapshot(
          liquidCash: 100,
          investments: 0,
          nonLiquidAssets: 0,
          liabilities: 1000,
        ).estimatedNetWorth,
        -900,
      );
      final zero = FinancialFootingSnapshot(
        liquidCash: 0,
        investments: 0,
        nonLiquidAssets: 0,
        liabilities: 0,
        monthlyEssentials: 100,
      );
      expect(zero.estimatedNetWorth, 0);
      expect(zero.cashBufferMonths, 0);
      expect(zero.hasReportedLiabilities, isFalse);
    });

    test('requires each balance sheet component to be entered', () {
      for (var omitted = 0; omitted < 4; omitted++) {
        final snapshot = FinancialFootingSnapshot(
          liquidCash: omitted == 0 ? null : 0,
          investments: omitted == 1 ? null : 0,
          nonLiquidAssets: omitted == 2 ? null : 0,
          liabilities: omitted == 3 ? null : 0,
        );
        expect(snapshot.estimatedNetWorth, isNull, reason: '$omitted');
      }
    });

    test('provides no buffer assessment with missing or zero essentials', () {
      for (final essentials in <double?>[null, 0]) {
        final snapshot = FinancialFootingSnapshot(
          liquidCash: 1000,
          monthlyEssentials: essentials,
          targetMonths: 1,
        );
        expect(snapshot.cashBufferMonths, isNull);
        expect(snapshot.bufferStatus, FinancialBufferStatus.unavailable);
      }
      final blank = FinancialFootingSnapshot();
      expect(blank.estimatedNetWorth, isNull);
      expect(blank.cashBufferMonths, isNull);
      expect(blank.bufferStatus, FinancialBufferStatus.unavailable);
      expect(blank.hasReportedLiabilities, isFalse);
    });

    test('uses only accessible cash and essential costs for the buffer', () {
      final snapshot = FinancialFootingSnapshot(
        liquidCash: 60000,
        investments: 500000,
        nonLiquidAssets: 10000000,
        liabilities: 1000000,
        monthlyEssentials: 30000,
      );
      expect(snapshot.cashBufferMonths, 2);
      expect(
        FinancialFootingSnapshot(
          investments: 500000,
          nonLiquidAssets: 10000000,
          monthlyEssentials: 30000,
        ).cashBufferMonths,
        isNull,
      );
    });

    test('compares the exact boundary of the personal target', () {
      for (final (cash, status) in [
        (0.29, FinancialBufferStatus.belowTarget),
        (0.30, FinancialBufferStatus.meetsTarget),
        (0.31, FinancialBufferStatus.meetsTarget),
      ]) {
        final snapshot = FinancialFootingSnapshot(
          liquidCash: cash,
          monthlyEssentials: 0.1,
          targetMonths: 3,
        );
        expect(snapshot.bufferStatus, status, reason: '$cash');
      }
      expect(
        FinancialFootingSnapshot(
          liquidCash: 0,
          monthlyEssentials: 30000,
          targetMonths: 0,
        ).bufferStatus,
        FinancialBufferStatus.meetsTarget,
      );
    });

    test('signals positive liabilities without assuming interest or terms', () {
      final snapshot = FinancialFootingSnapshot(liabilities: 1);
      expect(snapshot.hasReportedLiabilities, isTrue);
      expect(snapshot.estimatedNetWorth, isNull);
      expect(snapshot.bufferStatus, FinancialBufferStatus.unavailable);
    });

    test('guards invalid typed inputs and keeps extreme results finite', () {
      for (final invalid in [
        double.nan,
        double.infinity,
        -1.0,
        1e300,
        double.minPositive,
      ]) {
        final snapshot = FinancialFootingSnapshot(
          liquidCash: 1,
          investments: 0,
          nonLiquidAssets: 0,
          liabilities: invalid,
          monthlyEssentials: invalid,
        );
        expect(snapshot.estimatedNetWorth, isNull);
        expect(snapshot.cashBufferMonths, isNull);
        expect(snapshot.hasReportedLiabilities, isFalse);
      }

      final high = FinancialFootingSnapshot(
        liquidCash: maxFinancialFootingInput,
        investments: maxFinancialFootingInput,
        nonLiquidAssets: maxFinancialFootingInput,
        liabilities: 0,
        monthlyEssentials: .01,
        targetMonths: maxFinancialFootingInput,
      );
      expect(high.estimatedNetWorth, maxFinancialFootingInput * 3);
      expect(high.cashBufferMonths, maxFinancialFootingInput * 100);
      expect(high.bufferStatus, FinancialBufferStatus.meetsTarget);
      expect(
        FinancialFootingSnapshot(
          liquidCash: maxFinancialFootingInput,
          monthlyEssentials: maxFinancialFootingInput,
          targetMonths: maxFinancialFootingInput,
        ).bufferStatus,
        FinancialBufferStatus.belowTarget,
      );
    });
  });
}
