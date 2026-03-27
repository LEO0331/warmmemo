import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/widgets/common_widgets.dart';

void main() {
  testWidgets('SectionCard renders title and child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionCard(
            title: '測試區塊',
            icon: Icons.info_outline,
            child: Text('內容文字'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('測試區塊'), findsOneWidget);
    expect(find.text('內容文字'), findsOneWidget);
  });

  testWidgets('SkeletonOrderList renders expected number of skeleton cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SkeletonOrderList(count: 4),
        ),
      ),
    );

    expect(find.byType(SkeletonBox), findsNWidgets(12));
  });

  testWidgets('EmptyStateCard renders title and description', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyStateCard(
            title: '沒有資料',
            description: '請稍後再試',
          ),
        ),
      ),
    );

    expect(find.text('沒有資料'), findsOneWidget);
    expect(find.text('請稍後再試'), findsOneWidget);
  });

  testWidgets('Bullet renders bullet text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Bullet('重點文字'),
        ),
      ),
    );

    expect(find.text('• '), findsOneWidget);
    expect(find.text('重點文字'), findsOneWidget);
  });

  testWidgets('LabeledTextField validates input', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: LabeledTextField(
              label: '電話',
              controller: controller,
              validator: (v) {
                if ((v ?? '').isEmpty) return '不可空白';
                return null;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('電話'), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('不可空白'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '0912345678');
    expect(formKey.currentState!.validate(), isTrue);
  });
}
