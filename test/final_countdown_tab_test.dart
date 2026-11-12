import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warmmemo/features/final_countdown/final_countdown_tab.dart';
import 'package:warmmemo/features/final_countdown/financial_footing_card.dart';

const _draftKey = 'final_countdown_tab_v1';
const _expansionKey = 'financial_footing_expansion';
const _cashKey = 'financial_footing_liquid_cash';
const _netWorthKey = 'financial_footing_net_worth';
const _bufferKey = 'financial_footing_cash_buffer';
const _ageKey = 'current_age_field';

Finder _byKey(String key) => find.byKey(Key(key));

Finder _editable(String key) =>
    find.descendant(of: _byKey(key), matching: find.byType(EditableText));

Widget _app(Widget body, {Locale locale = const Locale('zh', 'TW')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('zh', 'TW'), Locale('en', 'US')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(body: body),
  );
}

void _expectMetric(WidgetTester tester, String key, String text) {
  final finder = find.descendant(of: _byKey(key), matching: find.byType(Text));
  expect(tester.widget<Text>(finder).data, text);
}

void _expectExistingProjection(WidgetTester tester) {
  _expectMetric(tester, 'summary_total_asset', r'預估終身資源：NT$ 150,000');
  _expectMetric(tester, 'summary_total_cost', r'預估終身支出：NT$ 50,000');
  _expectMetric(tester, 'summary_net', r'預估終身差額：NT$ 100,000');
  _expectMetric(tester, 'overall_readiness', '生活目標對齊度：84%');
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(_byKey(key));
  await tester.enterText(_editable(key), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'v1 draft and readiness are independent of the optional snapshot',
    (tester) async {
      final draft = <String, Object>{
        'currentAge': 40,
        'lifeExpectancy': 60,
        'retireYear': DateTime.now().year + 5,
        'targetLifeExpectancy': 65,
        'targetEndBalance': 85000,
        'costItems': [
          {'name': '必要支出', 'amount': '1,000', 'kind': 'annual'},
          {
            'name': '退休照護',
            'amount': 2000,
            'kind': 'annual',
            'phase': 'afterRetire',
          },
        ],
        'assetItems': [
          {'name': '一次性資產', 'amount': 100000},
          {
            'name': '工作收入',
            'amount': 10000,
            'kind': 'annual',
            'phase': 'beforeRetire',
          },
        ],
        'experienceItems': [
          {
            'title': '陪家人旅行',
            'completed': true,
            'satisfaction': 5,
            'category': 'travel',
          },
        ],
      };
      final savedDraft = jsonEncode(draft);
      SharedPreferences.setMockInitialValues({_draftKey: savedDraft});

      await tester.pumpWidget(_app(const FinalCountdownTab()));
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(_editable(_ageKey)).controller.text,
        '40',
      );
      expect(find.text('陪家人旅行'), findsOneWidget);
      _expectExistingProjection(tester);
      expect(_byKey(_cashKey), findsNothing);

      await tester.ensureVisible(_byKey(_expansionKey));
      await tester.tap(find.text('財務基礎與人生體驗'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(_editable(_cashKey)).controller.text,
        '',
      );
      expect(tester.widget<Text>(_byKey(_netWorthKey)).data, contains('無法估算'));
      expect(tester.widget<Text>(_byKey(_bufferKey)).data, contains('無法估算'));

      await _enter(tester, _cashKey, '432123');
      await _enter(tester, 'financial_footing_investments', '0');
      await _enter(tester, 'financial_footing_non_liquid_assets', '750000');
      await _enter(tester, 'financial_footing_liabilities', '100000');
      await _enter(tester, 'financial_footing_monthly_essentials', '144041');
      expect(
        tester.widget<Text>(_byKey(_netWorthKey)).data,
        contains('1,082,123'),
      );
      expect(tester.widget<Text>(_byKey(_bufferKey)).data, contains('3 個月'));
      await _enter(tester, 'financial_footing_target_months', '4');
      final planningContext = _byKey('financial_footing_context');
      expect(tester.widget<Text>(planningContext).data, contains('低於你選擇的目標'));
      await _enter(tester, 'financial_footing_target_months', '3');
      expect(tester.widget<Text>(planningContext).data, contains('已達到你選擇的目標'));
      _expectExistingProjection(tester);

      await tester.pump(const Duration(milliseconds: 350));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {_draftKey});
      expect(prefs.getString(_draftKey), savedDraft);

      // Saving an ordinary planner edit still excludes the current snapshot.
      await _enter(tester, _ageKey, '41');
      await tester.pump(const Duration(milliseconds: 350));
      expect(prefs.getKeys(), {_draftKey});
      final updated =
          jsonDecode(prefs.getString(_draftKey)!) as Map<String, dynamic>;
      expect(updated['currentAge'], 41);
      expect(updated.keys.toSet(), {
        ...draft.keys,
        'healthCurrent',
        'healthTarget',
      });
      expect(jsonEncode(updated), isNot(contains('432123')));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app(const FinalCountdownTab()));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(_editable(_ageKey)).controller.text,
        '41',
      );
      expect(_byKey(_cashKey), findsNothing);
      await tester.ensureVisible(_byKey(_expansionKey));
      await tester.tap(find.text('財務基礎與人生體驗'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(_editable(_cashKey)).controller.text,
        '',
      );
    },
  );

  testWidgets('financial footing supports keyboard navigation on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: FinancialFootingCard(),
        ),
        locale: const Locale('en', 'US'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.semantics.byLabel(RegExp('Financial Footing & Meaningful Spending')),
      findsOne,
    );
    expect(_byKey(_cashKey), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(_editable(_cashKey)).focusNode.hasFocus,
      isTrue,
    );
    expect(
      find.semantics.byLabel(RegExp(r'Accessible cash \(NT\$\)')),
      findsOne,
    );
    expect(tester.takeException(), isNull);
  });
}
