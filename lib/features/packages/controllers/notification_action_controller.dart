import 'package:flutter/foundation.dart';

import '../../../core/data/app_failure.dart';
import '../../../core/data/view_state.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationActionController {
  NotificationActionController({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository.instance;

  final NotificationRepository _repository;
  final ValueNotifier<ViewState> state = ValueNotifier<ViewState>(
    const IdleState(),
  );

  Future<void> markRead(String notificationId) async {
    try {
      await _repository.markReadOptimistic(notificationId);
      state.value = const SuccessState(message: '已標記為已讀');
    } catch (error) {
      state.value = ErrorState(AppFailure.from(error).message);
      rethrow;
    }
  }

  void dispose() {
    state.dispose();
  }
}
