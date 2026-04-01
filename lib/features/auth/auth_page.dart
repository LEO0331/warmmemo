import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/app_feedback.dart';
import '../../data/firebase/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.signIn,
    this.signUp,
  });

  final Future<void> Function(String email, String password)? signIn;
  final Future<void> Function(String email, String password)? signUp;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmailFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  final _registerEmailFocus = FocusNode();
  final _registerPasswordFocus = FocusNode();
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _loginEmailFocus.dispose();
    _loginPasswordFocus.dispose();
    _registerEmailFocus.dispose();
    _registerPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool isLogin}) async {
    final form = isLogin ? _loginFormKey.currentState : _registerFormKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _error = '請先修正欄位錯誤後再送出。');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

      try {
        if (isLogin) {
          final email = _loginEmail.text.trim();
          final password = _loginPassword.text.trim();
          if (widget.signIn != null) {
            await widget.signIn!(email, password);
          } else {
            await AuthService.instance.signIn(
              email: email,
              password: password,
            );
          }
        } else {
          final email = _registerEmail.text.trim();
          final password = _registerPassword.text.trim();
          if (widget.signUp != null) {
            await widget.signUp!(email, password);
          } else {
            await AuthService.instance.signUp(
              email: email,
              password: password,
            );
          }
        }
        if (mounted) {
          AppFeedback.show(
            context,
            message: isLogin ? '登入成功，歡迎回來。' : '註冊成功，歡迎加入 WarmMemo。',
            tone: FeedbackTone.success,
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } on FirebaseAuthException catch (e) {
        final message = _friendlyAuthError(e);
        setState(() => _error = message);
        if (mounted) {
          AppFeedback.show(
            context,
            message: message,
            tone: FeedbackTone.error,
          );
        }
      } on FirebaseException catch (e) {
        final message = _friendlyFirebaseError(e);
        setState(() => _error = message);
        if (mounted) {
          AppFeedback.show(
            context,
            message: message,
            tone: FeedbackTone.error,
          );
        }
      } catch (_) {
        const message = '發生未知錯誤，請稍後再試。';
        setState(() => _error = message);
        if (mounted) {
          AppFeedback.show(
            context,
            message: message,
            tone: FeedbackTone.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
  }

  String? _validateEmail(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) return '請輸入 Email。';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input);
    if (!ok) return 'Email 格式不正確。';
    return null;
  }

  String? _validatePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return '請輸入密碼。';
    if (input.length < 6) return '密碼至少需要 6 碼。';
    return null;
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email 格式不正確。';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return '帳號或密碼錯誤。';
      case 'email-already-in-use':
        return '這個 Email 已被註冊。';
      case 'weak-password':
        return '密碼強度不足，請至少 6 碼。';
      case 'too-many-requests':
        return '嘗試次數過多，請稍後再試。';
      default:
        return e.message ?? '登入失敗，請稍後再試。';
    }
  }

  String _friendlyFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return '登入成功，但資料讀取權限不足（permission-denied）。請稍後重整或聯絡管理員檢查 Firestore 規則。';
      case 'failed-precondition':
        return '目前資料庫設定尚未完成（failed-precondition），請先完成必要索引或設定。';
      default:
        return e.message ?? '資料服務暫時不可用，請稍後再試。';
    }
  }

  Widget _buildForm({
    required GlobalKey<FormState> formKey,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required FocusNode emailFocus,
    required FocusNode passwordFocus,
    required String title,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: emailController,
              focusNode: emailFocus,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
              onFieldSubmitted: (_) => passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              focusNode: passwordFocus,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
              onFieldSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isProcessing ? null : onSubmit,
                child: Text(title),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'WarmMemo 登入',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TabBar(
                tabs: const [Tab(text: '登入'), Tab(text: '註冊')],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildForm(
                      formKey: _loginFormKey,
                      emailController: _loginEmail,
                      passwordController: _loginPassword,
                      emailFocus: _loginEmailFocus,
                      passwordFocus: _loginPasswordFocus,
                      title: '登入',
                      onSubmit: () => _submit(isLogin: true),
                    ),
                    _buildForm(
                      formKey: _registerFormKey,
                      emailController: _registerEmail,
                      passwordController: _registerPassword,
                      emailFocus: _registerEmailFocus,
                      passwordFocus: _registerPasswordFocus,
                      title: '註冊',
                      onSubmit: () => _submit(isLogin: false),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
