import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  testWidgets('login submit shows friendly FirebaseAuthException message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(
          signIn: (email, password) async {
            // Intentionally throw auth error to verify user-facing message mapping.
            expect(email, isNotEmpty);
            expect(password, isNotEmpty);
            throw FirebaseAuthException(code: 'wrong-password');
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, '登入').first);
    await tester.pumpAndSettle();

    expect(find.text('帳號或密碼錯誤。'), findsWidgets);
  });

  testWidgets('register submit shows email already in use message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(
          signUp: (email, password) async {
            // Intentionally throw auth error to verify user-facing message mapping.
            expect(email, isNotEmpty);
            expect(password, isNotEmpty);
            throw FirebaseAuthException(code: 'email-already-in-use');
          },
        ),
      ),
    );

    await tester.tap(find.text('註冊'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'new@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, '註冊').first);
    await tester.pumpAndSettle();

    expect(find.text('這個 Email 已被註冊。'), findsWidgets);
  });

  testWidgets('successful login pops page when callback succeeds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AuthPage(
                        signIn: (email, password) async {
                          expect(email, 'user@test.com');
                          expect(password, '123456');
                        },
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, '登入').first);
    await tester.pumpAndSettle();

    expect(find.text('WarmMemo 登入'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
