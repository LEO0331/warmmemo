import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/widgets/app_feedback.dart';
import '../../core/utils/clear_payment_query_param_stub.dart'
    if (dart.library.html) '../../core/utils/clear_payment_query_param_web.dart';
import '../../data/firebase/auth_service.dart';
import '../../core/layout/app_shell.dart';
import '../../core/widgets/common_widgets.dart';
import '../landing/landing_page.dart';
import '../memorial/public_memorial_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _processingUnsupportedProvider = false;
  bool _handledPaymentHint = false;
  late final int _initialTabIndex = _resolveInitialTabIndex();

  @override
  Widget build(BuildContext context) {
    final publicSlug = _resolvePublicMemorialSlug();
    if (publicSlug != null) {
      return PublicMemorialPage(slug: publicSlug);
    }
    _handlePaymentQueryHint(context);
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SelectionArea(
            child: Scaffold(
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
            return const SelectionArea(child: LandingPage());
          }
          return SelectionArea(child: AppShell(initialIndex: _initialTabIndex));
        }

        return const SelectionArea(child: LandingPage());
      },
    );
  }

  void _handlePaymentQueryHint(BuildContext context) {
    if (_handledPaymentHint || !kIsWeb) return;
    _handledPaymentHint = true;
    final payment = Uri.base.queryParameters['payment'];
    if (payment == null) return;
    clearPaymentQueryParam();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (payment == 'success') {
        AppFeedback.show(
          context,
          message: '付款已完成，系統將由客服進一步核對。',
          tone: FeedbackTone.success,
        );
        return;
      }
      if (payment == 'cancel') {
        AppFeedback.show(
          context,
          message: '你已取消付款，可稍後重新開啟付款連結。',
          tone: FeedbackTone.info,
        );
        return;
      }
      AppFeedback.show(
        context,
        message: '收到付款狀態：$payment',
        tone: FeedbackTone.info,
      );
    });
  }

  int _resolveInitialTabIndex() {
    if (!kIsWeb) return 0;
    final fragment = Uri.base.fragment.toLowerCase();
    if (fragment.contains('packages')) {
      return 1;
    }
    return 0;
  }

  String? _resolvePublicMemorialSlug() {
    if (!kIsWeb) return null;
    final segments = Uri.base.pathSegments;
    if (segments.length >= 2 && segments.first.toLowerCase() == 'm') {
      final slug = segments[1].trim().toLowerCase();
      return slug.isEmpty ? null : slug;
    }

    final fragment = Uri.base.fragment.trim();
    if (fragment.isEmpty) return null;
    final normalized = fragment.startsWith('/')
        ? fragment.substring(1)
        : fragment;
    final fragSegments = normalized
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    if (fragSegments.length >= 2 && fragSegments.first.toLowerCase() == 'm') {
      final slug = fragSegments[1].trim().toLowerCase();
      return slug.isEmpty ? null : slug;
    }
    return null;
  }
}
