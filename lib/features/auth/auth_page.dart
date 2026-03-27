import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/firebase/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool isLogin}) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

      try {
        if (isLogin) {
          await AuthService.instance.signIn(
            email: _loginEmail.text.trim(),
            password: _loginPassword.text.trim(),
          );
        } else {
          await AuthService.instance.signUp(
            email: _registerEmail.text.trim(),
            password: _registerPassword.text.trim(),
          );
        }
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _error = _friendlyAuthError(e));
      } catch (_) {
        setState(() => _error = '發生未知錯誤，請稍後再試。');
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
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

  Widget _buildForm({
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required String title,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
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
                      emailController: _loginEmail,
                      passwordController: _loginPassword,
                      title: '登入',
                      onSubmit: () => _submit(isLogin: true),
                    ),
                    _buildForm(
                      emailController: _registerEmail,
                      passwordController: _registerPassword,
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
