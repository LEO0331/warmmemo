import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warmmemo/features/final_countdown/final_countdown_tab.dart';

void main() {
  Widget app() {
    return const MaterialApp(home: Scaffold(body: FinalCountdownTab()));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders sections and controls', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('人生倒數與零結餘規劃'), findsOneWidget);
    expect(find.text('倒數參數'), findsOneWidget);
    expect(find.text('零結餘結果'), findsOneWidget);
    expect(find.text('新增支出項目'), findsOneWidget);
    expect(find.text('新增資產項目'), findsOneWidget);
    expect(find.text('退休前'), findsWidgets);
    expect(find.text('退休後'), findsWidgets);
  });

  testWidgets('phase split changes net amount', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final nowYear = DateTime.now().year;
    await tester.enterText(
      find.byKey(const Key('retire_year_field')),
      '${nowYear + 10}',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('差額（資產 - 支出）：NT\$ 16,380,000'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('退休後').last,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('退休後').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('差額（資產 - 支出）：NT\$ 43,380,000'), findsOneWidget);
  });

  testWidgets('amount formatter and validation', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final amountField = find.widgetWithText(TextFormField, '金額（NT\$）').first;
    await tester.enterText(amountField, '1234567');
    await tester.pumpAndSettle();

    final widget = tester.widget<TextFormField>(amountField);
    expect(widget.controller?.text, '1234567');

    await tester.enterText(amountField, '');
    await tester.pumpAndSettle();
    expect(find.text('請輸入金額'), findsOneWidget);
  });

  testWidgets('loads saved draft', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'final_countdown_tab_v1': jsonEncode(<String, Object>{
        'currentAge': '40',
        'lifeExpectancy': '60',
        'retireYear': '${DateTime.now().year + 5}',
        'costItems': <Map<String, Object>>[
          <String, Object>{
            'name': '測試支出',
            'amount': '100',
            'kind': 'oneTime',
            'phase': 'allYears',
          },
        ],
        'assetItems': <Map<String, Object>>[
          <String, Object>{
            'name': '測試資產',
            'amount': '500',
            'kind': 'oneTime',
            'phase': 'allYears',
          },
        ],
      }),
    });

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final currentAge = tester.widget<TextFormField>(
      find.byKey(const Key('current_age_field')),
    );
    expect(currentAge.controller?.text, '40');
    expect(find.textContaining('差額（資產 - 支出）：NT\$ 400'), findsOneWidget);
  });

  testWidgets('quick add and delete item updates list', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final beforeDeleteButtons = find.byTooltip('刪除');
    final beforeCount = tester
        .widgetList<IconButton>(beforeDeleteButtons)
        .length;

    await tester.scrollUntilVisible(
      find.text('加入旅行'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('加入旅行'));
    await tester.pumpAndSettle();

    final afterAddCount = tester
        .widgetList<IconButton>(find.byTooltip('刪除'))
        .length;
    expect(afterAddCount, greaterThan(beforeCount));

    await tester.scrollUntilVisible(
      find.byTooltip('刪除').last,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('刪除').last);
    await tester.pumpAndSettle();
    final afterDeleteCount = tester
        .widgetList<IconButton>(find.byTooltip('刪除'))
        .length;
    expect(afterDeleteCount, afterAddCount - 1);
  });

  testWidgets(
    'supports quick add chips and manual add buttons for both panels',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('加入健康'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('加入健康'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('加入贈與'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('新增支出項目'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('新增支出項目'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('加入存款'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('加入存款'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('加入股票'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('加入收入'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('新增資產項目'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('新增資產項目'));
      await tester.pumpAndSettle();

      final deleteCount = tester
          .widgetList<IconButton>(find.byTooltip('刪除'))
          .length;
      expect(deleteCount, greaterThan(6));
    },
  );

  testWidgets('can toggle amount kind and phase chips', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('每年金額').first,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('每年金額').first);
    await tester.pumpAndSettle();
    expect(find.text('全期間'), findsWidgets);
    expect(find.text('退休前'), findsWidgets);
    expect(find.text('退休後'), findsWidgets);

    await tester.tap(find.text('退休前').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('退休後').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('單次金額').first);
    await tester.pumpAndSettle();
  });

  testWidgets('shows empty states after deleting all items', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    while (find.byTooltip('刪除').evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        find.byTooltip('刪除').last,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('刪除').last);
      await tester.pumpAndSettle();
    }

    expect(find.text('尚未新增支出項目'), findsOneWidget);
    expect(find.text('尚未新增資產項目'), findsOneWidget);
  });

  testWidgets('renders wide layout and supports decimal amount input', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final amountField = find.widgetWithText(TextFormField, '金額（NT\$）').first;
    await tester.enterText(amountField, '12.3');
    await tester.pumpAndSettle();

    expect(find.byType(Row), findsWidgets);
    expect(find.textContaining('差額（資產 - 支出）'), findsOneWidget);
  });
}
