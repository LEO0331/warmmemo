import 'dart:async';

/// Route changes are browser-only; native targets do not expose URL events.
Stream<void> get browserRouteChanges => const Stream<void>.empty();
