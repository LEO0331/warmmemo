import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/features/auth/auth_page.dart';

void main() {
  testWidgets('login tab validates email and password', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));

    final loginSubmitButton = find.widgetWithText(FilledButton, '登入').first;
    await tester.tap(loginSubmitButton);
    await tester.pumpAndSettle();

    expect(find.text('請輸入 Email。'), findsWidgets);
    expect(find.text('請輸入密碼。'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'bad_email');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(loginSubmitButton);
    await tester.pumpAndSettle();

    expect(find.text('Email 格式不正確。'), findsOneWidget);
    expect(find.text('密碼至少需要 6 碼。'), findsOneWidget);
  });

  testWidgets('register tab validates form fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));

    await tester.tap(find.text('註冊'));
    await tester.pumpAndSettle();

    final registerButton = find.widgetWithText(FilledButton, '註冊').first;
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('請輸入 Email。'), findsWidgets);
    expect(find.text('請輸入密碼。'), findsWidgets);
  });

  testWidgets('login submit shows fallback unknown error when auth call fails', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');

    final loginSubmitButton = find.widgetWithText(FilledButton, '登入').first;
    await tester.tap(loginSubmitButton);
    await tester.pumpAndSettle();

    expect(find.text('發生未知錯誤，請稍後再試。'), findsWidgets);
  });
}
