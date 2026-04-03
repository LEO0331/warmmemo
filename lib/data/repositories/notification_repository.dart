import 'dart:async';

import '../../core/data/cache_store.dart';
import '../../core/data/memory_cache_store.dart';
import '../../core/data/request_policy.dart';
import '../../core/data/retry.dart';
import '../models/draft_models.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  NotificationRepository({
    NotificationService? service,
    CacheStore<String, List<NotificationEvent>>? cache,
  }) : _service = service ?? NotificationService.instance,
       _cache = cache ?? MemoryCacheStore<String, List<NotificationEvent>>();

  static final NotificationRepository instance = NotificationRepository();

  final NotificationService _service;
  final CacheStore<String, List<NotificationEvent>> _cache;
  final Map<String, Future<List<NotificationEvent>>> _inflight =
      <String, Future<List<NotificationEvent>>>{};
  final Set<String> _optimisticRead = <String>{};
  final Map<String, Set<String>> _keysByNotificationId =
      <String, Set<String>>{};

  Stream<List<NotificationEvent>> watchForUser(
    String userId, {
    int limit = 20,
    RequestPolicy policy = const RequestPolicy(),
  }) {
    final key = _cacheKey(userId, limit);
    return _service.streamForUser(userId, limit: limit).map((items) {
      final merged = _applyOptimistic(items);
      _registerNotificationKeys(key, merged);
      _cache.set(key, merged, ttl: policy.ttl);
      return merged;
    });
  }

  Future<List<NotificationEvent>> fetchForUser(
    String userId, {
    int limit = 100,
    bool forceRefresh = false,
    RequestPolicy policy = const RequestPolicy(),
  }) async {
    final key = _cacheKey(userId, limit);
    if (!forceRefresh) {
      final cached = _cache.get(key);
      if (cached != null) return cached;
    }
    final running = _inflight[key];
    if (running != null) return running;

    final future = withRetry(() async {
      final items = await _service.fetchForUser(userId, limit: limit);
      final merged = _applyOptimistic(items);
      _registerNotificationKeys(key, merged);
      _cache.set(key, merged, ttl: policy.ttl);
      return merged;
    }, policy: policy);

    _inflight[key] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<void> markReadOptimistic(String notificationId) async {
    _optimisticRead.add(notificationId);
    _invalidateNotificationKeys(notificationId);
    try {
      await _service.markRead(notificationId);
      _optimisticRead.remove(notificationId);
    } catch (_) {
      _optimisticRead.remove(notificationId);
      _invalidateNotificationKeys(notificationId);
      rethrow;
    }
  }

  List<NotificationEvent> _applyOptimistic(List<NotificationEvent> source) {
    if (_optimisticRead.isEmpty) return source;
    return source.map((item) {
      if (item.id == null || !_optimisticRead.contains(item.id)) return item;
      return NotificationEvent(
        id: item.id,
        userId: item.userId,
        channel: item.channel,
        status: 'read',
        occurredAt: item.occurredAt,
        tone: item.tone,
        draftType: item.draftType,
      );
    }).toList();
  }

  String _cacheKey(String userId, int limit) => 'notifications:$userId:$limit';

  void _registerNotificationKeys(
    String key,
    List<NotificationEvent> notifications,
  ) {
    for (final item in notifications) {
      final id = item.id;
      if (id == null || id.isEmpty) continue;
      final keys = _keysByNotificationId.putIfAbsent(id, () => <String>{});
      keys.add(key);
    }
  }

  void _invalidateNotificationKeys(String notificationId) {
    final keys = _keysByNotificationId[notificationId];
    if (keys == null || keys.isEmpty) return;
    for (final key in keys) {
      _cache.invalidate(key);
    }
  }
}
