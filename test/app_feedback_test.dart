import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/widgets/app_feedback.dart';

void main() {
  testWidgets('AppFeedback shows message and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () {
                  AppFeedback.show(
                    context,
                    message: '操作失敗',
                    tone: FeedbackTone.error,
                    actionLabel: '重試',
                    onAction: () {},
                  );
                },
                child: const Text('show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.text('操作失敗'), findsOneWidget);
    expect(find.text('重試'), findsOneWidget);
  });

  testWidgets('AppFeedback success tone also shows message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () {
                  AppFeedback.show(
                    context,
                    message: '完成',
                    tone: FeedbackTone.success,
                  );
                },
                child: const Text('show2'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show2'));
    await tester.pump();
    expect(find.text('完成'), findsOneWidget);
  });

  testWidgets('AppFeedback info tone works without action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () {
                  AppFeedback.show(
                    context,
                    message: '資訊提示',
                    tone: FeedbackTone.info,
                  );
                },
                child: const Text('show3'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show3'));
    await tester.pump();
    expect(find.text('資訊提示'), findsOneWidget);
  });
}
