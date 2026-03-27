import 'package:flutter/material.dart';

enum FeedbackTone {
  success,
  error,
  info,
}

class AppFeedback {
  static void showWithMessenger(
    ScaffoldMessengerState messenger, {
    required ColorScheme colorScheme,
    required String message,
    FeedbackTone tone = FeedbackTone.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      showCloseIcon: true,
      duration: const Duration(seconds: 4),
      backgroundColor: switch (tone) {
        FeedbackTone.success => const Color(0xFF2D6A4F),
        FeedbackTone.error => colorScheme.errorContainer,
        FeedbackTone.info => const Color(0xFF5E503F),
      },
      content: Text(
        message,
        style: TextStyle(
          color: switch (tone) {
            FeedbackTone.success => Colors.white,
            FeedbackTone.error => colorScheme.onErrorContainer,
            FeedbackTone.info => Colors.white,
          },
        ),
      ),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: tone == FeedbackTone.error ? colorScheme.primary : const Color(0xFFF7E1C8),
              onPressed: onAction,
            )
          : null,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void show(
    BuildContext context, {
    required String message,
    FeedbackTone tone = FeedbackTone.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showWithMessenger(
      ScaffoldMessenger.of(context),
      colorScheme: Theme.of(context).colorScheme,
      message: message,
      tone: tone,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
