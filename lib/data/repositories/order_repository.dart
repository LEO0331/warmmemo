import 'dart:async';

import '../../core/data/cache_store.dart';
import '../../core/data/memory_cache_store.dart';
import '../../core/data/request_policy.dart';
import '../../core/data/retry.dart';
import '../models/purchase.dart';
import '../services/purchase_service.dart';

class OrderRepository {
  OrderRepository({
    PurchaseService? service,
    CacheStore<String, List<Purchase>>? cache,
  }) : _service = service ?? PurchaseService.instance,
       _cache = cache ?? MemoryCacheStore<String, List<Purchase>>();

  static final OrderRepository instance = OrderRepository();

  final PurchaseService _service;
  final CacheStore<String, List<Purchase>> _cache;
  final Map<String, Future<List<Purchase>>> _inflight =
      <String, Future<List<Purchase>>>{};
  final Map<String, Map<String, Purchase>> _optimisticByUid =
      <String, Map<String, Purchase>>{};

  Stream<List<Purchase>> watchOrders(
    String uid, {
    RequestPolicy policy = const RequestPolicy(),
  }) {
    return _service.userOrders(uid).map((items) {
      _cache.set(_cacheKey(uid), items, ttl: policy.ttl);
      return _mergeOptimistic(uid, items);
    });
  }

  Future<List<Purchase>> fetchOrders(
    String uid, {
    bool forceRefresh = false,
    RequestPolicy policy = const RequestPolicy(),
  }) async {
    final key = _cacheKey(uid);
    if (!forceRefresh) {
      final cached = _cache.get(key);
      if (cached != null) return _mergeOptimistic(uid, cached);
    }
    final running = _inflight[key];
    if (running != null) return running;

    final future = withRetry(() async {
      final first = await _service.userOrders(uid).first;
      _cache.set(key, first, ttl: policy.ttl);
      return _mergeOptimistic(uid, first);
    }, policy: policy);

    _inflight[key] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<void> updateOrderOptimistic({
    required String uid,
    required Purchase previous,
    required Purchase next,
  }) async {
    final orderId = next.id;
    if (orderId == null || orderId.isEmpty) {
      await _service.updateOrder(uid: uid, purchase: next);
      return;
    }

    final optimisticMap = _optimisticByUid.putIfAbsent(
      uid,
      () => <String, Purchase>{},
    );
    optimisticMap[orderId] = next;

    final key = _cacheKey(uid);
    final cached = _cache.get(key);
    if (cached != null) {
      final replaced = cached
          .map((item) => item.id == orderId ? next : item)
          .toList();
      _cache.set(key, replaced);
    }

    try {
      await _service.updateOrder(uid: uid, purchase: next);
      optimisticMap.remove(orderId);
      _cache.invalidate(key);
    } catch (_) {
      optimisticMap[orderId] = previous;
      if (cached != null) {
        final rollback = cached
            .map((item) => item.id == orderId ? previous : item)
            .toList();
        _cache.set(key, rollback);
      }
      rethrow;
    }
  }

  List<Purchase> _mergeOptimistic(String uid, List<Purchase> source) {
    final optimistic = _optimisticByUid[uid];
    if (optimistic == null || optimistic.isEmpty) return source;
    return source.map((item) {
      final id = item.id;
      if (id == null) return item;
      return optimistic[id] ?? item;
    }).toList();
  }

  String _cacheKey(String uid) => 'orders:$uid';
}
