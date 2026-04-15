import 'package:patrol/patrol.dart';

import 'package:warmmemo/main.dart' as app;

void main() {
  patrolTest('landing loads and can open auth page', ($) async {
    app.main();
    await $.pumpAndSettle();

    await $(#OpenAuthButton).waitUntilVisible();
    await $(#OpenAuthButton).tap();
    await $.pumpAndSettle();

    await $('登入').waitUntilVisible();
    await $('註冊').waitUntilVisible();
  });

  patrolTest('login form shows validation errors on empty submit', ($) async {
    app.main();
    await $.pumpAndSettle();

    await $(#OpenAuthButton).waitUntilVisible();
    await $(#OpenAuthButton).tap();
    await $.pumpAndSettle();

    await $(#auth_login_submit_button).tap();
    await $.pumpAndSettle();

    await $('請輸入 Email。').waitUntilVisible();
    await $('請輸入密碼。').waitUntilVisible();
    await $('請先修正欄位錯誤後再送出。').waitUntilVisible();
  });

  patrolTest('register form validates email and password format', ($) async {
    app.main();
    await $.pumpAndSettle();

    await $(#OpenAuthButton).waitUntilVisible();
    await $(#OpenAuthButton).tap();
    await $.pumpAndSettle();

    await $(#auth_register_tab).tap();
    await $.pumpAndSettle();

    await $(#auth_register_email_field).enterText('not-an-email');
    await $(#auth_register_password_field).enterText('123');
    await $(#auth_register_submit_button).tap();
    await $.pumpAndSettle();

    await $('Email 格式不正確。').waitUntilVisible();
    await $('密碼至少需要 6 碼。').waitUntilVisible();
  });

  patrolTest('landing CTA 開始規劃 can open auth page', ($) async {
    app.main();
    await $.pumpAndSettle();

    await $('開始規劃').waitUntilVisible();
    await $('開始規劃').tap();
    await $.pumpAndSettle();

    await $('WarmMemo 登入').waitUntilVisible();
    await $(#auth_login_submit_button).waitUntilVisible();
    await $(#auth_register_tab).waitUntilVisible();
  });
}
