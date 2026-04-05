class InputGuard {
  static final RegExp _controlChars = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );

  static String singleLine(String input, {required int maxLength}) {
    var value = input.replaceAll(_controlChars, '');
    value = value.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    value = value.replaceAll('<', '＜').replaceAll('>', '＞');
    value = value.trim();
    if (value.length > maxLength) {
      value = value.substring(0, maxLength).trim();
    }
    return value;
  }

  static String multiline(String input, {required int maxLength}) {
    var value = input.replaceAll(_controlChars, '');
    value = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    value = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    value = value.replaceAll('<', '＜').replaceAll('>', '＞');
    value = value.trim();
    if (value.length > maxLength) {
      value = value.substring(0, maxLength).trim();
    }
    return value;
  }

  static String dateOrText(String input, {required int maxLength}) {
    final cleaned = singleLine(input, maxLength: maxLength);
    if (cleaned.isEmpty) return '';
    final normalized = cleaned.replaceAll('/', '-');
    final dateMatch = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})$',
    ).firstMatch(normalized);
    if (dateMatch != null) {
      final year = int.tryParse(dateMatch.group(1) ?? '');
      final month = int.tryParse(dateMatch.group(2) ?? '');
      final day = int.tryParse(dateMatch.group(3) ?? '');
      if (year != null &&
          month != null &&
          day != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
    }
    final monthMatch = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(normalized);
    if (monthMatch != null) {
      final year = int.tryParse(monthMatch.group(1) ?? '');
      final month = int.tryParse(monthMatch.group(2) ?? '');
      if (year != null && month != null && month >= 1 && month <= 12) {
        return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
      }
    }
    return cleaned;
  }

  static int boundedInt(
    String input, {
    required int fallback,
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse(input.trim()) ?? fallback;
    return parsed.clamp(min, max);
  }

  static double boundedAmount(String input, {double max = 999999999999}) {
    final parsed = double.tryParse(input.replaceAll(',', '').trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;
    return parsed.clamp(0, max);
  }
}
