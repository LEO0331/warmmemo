import 'dart:async';

import '../../core/data/cache_store.dart';
import '../../core/data/memory_cache_store.dart';
import '../../core/data/request_policy.dart';
import '../../core/data/retry.dart';
import '../models/vendor.dart';
import '../services/vendor_service.dart';

class VendorRepository {
  VendorRepository({
    VendorService? service,
    CacheStore<String, List<Vendor>>? cache,
  }) : _service = service ?? VendorService.instance,
       _cache = cache ?? MemoryCacheStore<String, List<Vendor>>();

  static final VendorRepository instance = VendorRepository();

  final VendorService _service;
  final CacheStore<String, List<Vendor>> _cache;
  final Map<String, Future<List<Vendor>>> _inflight =
      <String, Future<List<Vendor>>>{};
  final Map<String, bool> _optimisticActive = <String, bool>{};

  Stream<List<Vendor>> watchVendors({
    bool includeInactive = true,
    RequestPolicy policy = const RequestPolicy(),
  }) {
    final key = _cacheKey(includeInactive);
    return _service.streamVendors(includeInactive: includeInactive).map((
      items,
    ) {
      final merged = _applyOptimistic(items);
      _cache.set(key, merged, ttl: policy.ttl);
      return merged;
    });
  }

  Future<List<Vendor>> fetchVendors({
    bool includeInactive = true,
    bool forceRefresh = false,
    RequestPolicy policy = const RequestPolicy(),
  }) async {
    final key = _cacheKey(includeInactive);
    if (!forceRefresh) {
      final cached = _cache.get(key);
      if (cached != null) return cached;
    }
    final running = _inflight[key];
    if (running != null) return running;

    final future = withRetry(() async {
      final first = await _service
          .streamVendors(includeInactive: includeInactive)
          .first;
      final merged = _applyOptimistic(first);
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

  Future<void> createVendor(Vendor vendor) {
    _cache.clear();
    return _service.createVendor(vendor);
  }

  Future<bool> nameExists(String name) {
    return _service.nameExists(name);
  }

  Future<void> toggleVendorActiveOptimistic({
    required Vendor vendor,
    required bool nextActive,
  }) async {
    final id = vendor.id;
    if (id == null || id.isEmpty) return;
    _optimisticActive[id] = nextActive;

    for (final cacheKey in ['vendors:all', 'vendors:active']) {
      final cached = _cache.get(cacheKey);
      if (cached == null) continue;
      final replaced = cached
          .map(
            (item) =>
                item.id == id ? item.copyWith(isActive: nextActive) : item,
          )
          .toList();
      _cache.set(cacheKey, replaced);
    }

    try {
      await _service.setVendorActive(vendorId: id, isActive: nextActive);
      _optimisticActive.remove(id);
      _cache.clear();
    } catch (_) {
      _optimisticActive[id] = vendor.isActive;
      _cache.clear();
      rethrow;
    }
  }

  List<Vendor> _applyOptimistic(List<Vendor> source) {
    if (_optimisticActive.isEmpty) return source;
    return source.map((item) {
      final id = item.id;
      if (id == null) return item;
      final override = _optimisticActive[id];
      if (override == null) return item;
      return item.copyWith(isActive: override);
    }).toList();
  }

  String _cacheKey(bool includeInactive) =>
      includeInactive ? 'vendors:all' : 'vendors:active';
}
