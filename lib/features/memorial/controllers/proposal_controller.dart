import 'package:flutter/foundation.dart';

import '../../../core/data/app_failure.dart';
import '../../../core/data/view_state.dart';
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
}
