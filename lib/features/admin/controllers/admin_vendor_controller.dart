import 'package:flutter/foundation.dart';

import '../../../core/data/app_failure.dart';
import '../../../core/data/view_state.dart';
import '../../../data/models/vendor.dart';
import '../../../data/repositories/vendor_repository.dart';

class AdminVendorController {
  AdminVendorController({VendorRepository? repository})
    : _repository = repository ?? VendorRepository.instance;

  final VendorRepository _repository;
  final ValueNotifier<ViewState> state = ValueNotifier<ViewState>(
    const IdleState(),
  );

  Future<void> createVendor(Vendor vendor) async {
    state.value = const LoadingState();
    try {
      await _repository.createVendor(vendor);
      state.value = const SuccessState(message: '供應商已新增');
    } catch (error) {
      state.value = ErrorState(AppFailure.from(error).message);
      rethrow;
    }
  }

  Future<void> toggleVendorActive({
    required Vendor vendor,
    required bool nextActive,
  }) async {
    try {
      await _repository.toggleVendorActiveOptimistic(
        vendor: vendor,
        nextActive: nextActive,
      );
      state.value = const SuccessState();
    } catch (error) {
      state.value = ErrorState(AppFailure.from(error).message);
      rethrow;
    }
  }

  void dispose() {
    state.dispose();
  }
}
