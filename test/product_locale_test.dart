import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/utils/product_locale.dart';

void main() {
  testWidgets('product copy uses English for an English locale', (tester) async {
    late String copy;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        supportedLocales: const [Locale('zh', 'TW'), Locale('en', 'US')],
        home: Builder(
          builder: (context) {
            copy = productCopy(context, zh: '繁體中文', en: 'English');
            return const SizedBox();
          },
        ),
      ),
    );

    expect(copy, 'English');
  });
}
