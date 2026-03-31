import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/features/final_countdown/final_countdown_tab.dart';

void main() {
  Widget testApp() {
    return const MaterialApp(
      home: Scaffold(body: FinalCountdownTab()),
    );
  }

  testWidgets('renders key sections and default controls', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.byType(FinalCountdownTab), findsOneWidget);
    expect(find.text('人生倒數與零結餘規劃'), findsOneWidget);
    expect(find.text('倒數參數'), findsOneWidget);
    expect(find.text('零結餘結果'), findsOneWidget);
    expect(find.text('新增支出項目'), findsOneWidget);
    expect(find.text('新增資產項目'), findsOneWidget);
  });

  testWidgets('recomputes totals when input changes', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('差額（資產 - 支出）：NT\$ 52,080,000'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '80');
    await tester.pumpAndSettle();

    expect(find.textContaining('剩餘年數：5 年'), findsOneWidget);
    expect(find.textContaining('差額（資產 - 支出）：NT\$ 14,550,000'), findsOneWidget);
  });

  testWidgets('supports add and remove item operations', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNWidgets(6));
    expect(find.textContaining('總資產：NT\$ 55,500,000'), findsOneWidget);

    await tester.tap(find.text('加入存款'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(7));
    expect(find.textContaining('總資產：NT\$ 56,500,000'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(6));
  });
}
