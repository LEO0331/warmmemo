import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/firebase/auth_service.dart';
import '../../data/services/user_role_service.dart';
import '../../core/layout/app_shell.dart';
import '../../core/widgets/common_widgets.dart';
import '../landing/landing_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _processingUnsupportedProvider = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60),
                  SkeletonBox(height: 26, width: 180),
                  SizedBox(height: 16),
                  SkeletonBox(height: 14),
                  SizedBox(height: 10),
                  SkeletonBox(height: 14, width: 260),
                  SizedBox(height: 22),
                  SkeletonOrderList(count: 3),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (!AuthService.instance.isEmailPasswordUser(user)) {
            if (!_processingUnsupportedProvider) {
              _processingUnsupportedProvider = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final messenger = ScaffoldMessenger.of(context);
                await AuthService.instance.signOut();
                _processingUnsupportedProvider = false;
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('目前僅支援 Email / Password 登入。')),
                );
              });
            }
            return const LandingPage();
          }
          UserRoleService.instance.ensureUserProfile(user);
          return const AppShell();
        }

        return const LandingPage();
      },
    );
  }
}
