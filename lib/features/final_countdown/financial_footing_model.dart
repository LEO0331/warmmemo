const maxFinancialFootingInput = 999999999999.0;
const _inputScale = 100;

final _decimalInput = RegExp(
  r'^(?:(?:\d{1,12}|\d{1,3}(?:,\d{3}){1,3})(?:\.\d{1,2})?|\.\d{1,2})$',
);

/// Follows the planner's InputGuard conventions for whitespace and grouping.
/// Blank and invalid inputs retain their own states for the optional fields.
({double? value, bool isInvalid}) parseFinancialFootingInput(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return (value: null, isInvalid: false);
  if (!_decimalInput.hasMatch(input)) return (value: null, isInvalid: true);

  final value = double.tryParse(input.replaceAll(',', ''));
  if (_scaledInput(value) == null) return (value: null, isInvalid: true);
  return (value: value, isInvalid: false);
}

enum FinancialBufferStatus { unavailable, noTarget, belowTarget, meetsTarget }

class FinancialFootingSnapshot {
  factory FinancialFootingSnapshot({
    double? liquidCash,
    double? investments,
    double? nonLiquidAssets,
    double? liabilities,
    double? monthlyEssentials,
    double? targetMonths,
  }) {
    final cash = _scaledInput(liquidCash);
    final invested = _scaledInput(investments);
    final illiquid = _scaledInput(nonLiquidAssets);
    final debt = _scaledInput(liabilities);
    final essentials = _scaledInput(monthlyEssentials);
    final target = _scaledInput(targetMonths);

    final netWorth =
        cash != null && invested != null && illiquid != null && debt != null
        ? (cash + invested + illiquid - debt) / _inputScale
        : null;

    if (cash == null || essentials == null || essentials == 0) {
      return FinancialFootingSnapshot._(
        netWorth,
        null,
        FinancialBufferStatus.unavailable,
        debt != null && debt > 0,
      );
    }

    return FinancialFootingSnapshot._(
      netWorth,
      cash / essentials,
      _compareBuffer(cash, essentials, target),
      debt != null && debt > 0,
    );
  }

  const FinancialFootingSnapshot._(
    this.estimatedNetWorth,
    this.cashBufferMonths,
    this.bufferStatus,
    this.hasReportedLiabilities,
  );

  final double? estimatedNetWorth;
  final double? cashBufferMonths;
  final FinancialBufferStatus bufferStatus;
  final bool hasReportedLiabilities;
}

int? _scaledInput(double? value) {
  if (value == null ||
      !value.isFinite ||
      value < 0 ||
      value > maxFinancialFootingInput) {
    return null;
  }
  final scaled = (value * _inputScale).round();
  return scaled / _inputScale == value ? scaled : null;
}

FinancialBufferStatus _compareBuffer(int cash, int essentials, int? target) {
  if (target == null) return FinancialBufferStatus.noTarget;

  // Exact comparison at the selected target, including products beyond the
  // safe integer range on the web. The reported ratio can use a double.
  final available = BigInt.from(cash) * BigInt.from(_inputScale);
  final required = BigInt.from(essentials) * BigInt.from(target);
  return available < required
      ? FinancialBufferStatus.belowTarget
      : FinancialBufferStatus.meetsTarget;
}
