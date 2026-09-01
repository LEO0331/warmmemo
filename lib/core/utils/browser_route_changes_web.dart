// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

/// Emits whenever browser history or a hash URL changes without rebuilding the
/// Flutter application from scratch.
Stream<void> get browserRouteChanges => Stream<void>.multi((controller) {
  final hashSubscription = html.window.onHashChange.listen(
    (_) => controller.add(null),
  );
  final popStateSubscription = html.window.onPopState.listen(
    (_) => controller.add(null),
  );

  controller.onCancel = () async {
    await hashSubscription.cancel();
    await popStateSubscription.cancel();
  };
});
