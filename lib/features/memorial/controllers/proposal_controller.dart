import 'package:flutter/foundation.dart';

import '../../../core/data/app_failure.dart';
import '../../../core/data/view_state.dart';
import '../../../core/utils/input_guard.dart';
import '../../../data/models/purchase.dart';
import '../../../data/repositories/order_repository.dart';

class ProposalController {
  ProposalController({OrderRepository? repository})
    : _repository = repository ?? OrderRepository.instance;

  final OrderRepository _repository;
  final ValueNotifier<ViewState> state = ValueNotifier<ViewState>(
    const IdleState(),
  );

  Future<void> submit({
    required String uid,
    required Purchase previous,
    required Purchase next,
  }) async {
    final validation = _validate(next);
    if (validation != null) {
      state.value = ErrorState(validation);
      throw ValidationFailure(validation);
    }
    state.value = const LoadingState();
    try {
      await _repository.updateOrderOptimistic(
        uid: uid,
        previous: previous,
        next: next,
      );
      state.value = const SuccessState(message: '提案已送出，Admin 會進一步審核與指派。');
    } catch (error) {
      final failure = AppFailure.from(error);
      state.value = ErrorState(failure.message);
      rethrow;
    }
  }

  Future<void> retry({
    required String uid,
    required Purchase previous,
    required Purchase next,
  }) {
    return submit(uid: uid, previous: previous, next: next);
  }

  void dispose() {
    state.dispose();
  }

  String? _validate(Purchase purchase) {
    final proposal = purchase.proposal;
    if (proposal == null || proposal.isEmpty) {
      return '提案內容不可為空。';
    }
    final vendor = InputGuard.singleLine(
      proposal.vendorPreference ?? '',
      maxLength: 60,
    );
    final schedule = InputGuard.dateOrText(
      proposal.schedulePreference ?? '',
      maxLength: 80,
    );
    final note = InputGuard.multiline(proposal.note ?? '', maxLength: 240);
    if (vendor.isEmpty && schedule.isEmpty && note.isEmpty) {
      return '請至少填寫一項提案偏好。';
    }
    if (proposal.vendorPreference != null &&
        vendor != proposal.vendorPreference) {
      return '供應商偏好格式不正確，請重新輸入。';
    }
    if (proposal.schedulePreference != null &&
        schedule != proposal.schedulePreference) {
      return '希望完成時間格式不正確。';
    }
    if (proposal.note != null && note != proposal.note) {
      return '補充說明包含不支援內容，請調整後再送出。';
    }
    return null;
  }
}
