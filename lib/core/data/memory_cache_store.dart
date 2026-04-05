import 'cache_store.dart';

class MemoryCacheStore<K, V> implements CacheStore<K, V> {
  final Map<K, _Entry<V>> _memory = <K, _Entry<V>>{};

  @override
  V? get(K key) {
    final item = _memory[key];
    if (item == null) return null;
    if (DateTime.now().isAfter(item.expiresAt)) {
      _memory.remove(key);
      return null;
    }
    return item.value;
  }

  @override
  bool hasValid(K key) {
    return get(key) != null;
  }

  @override
  void set(K key, V value, {Duration? ttl}) {
    final lifetime = ttl ?? const Duration(seconds: 30);
    _memory[key] = _Entry<V>(
      value: value,
      expiresAt: DateTime.now().add(lifetime),
    );
  }

  @override
  void invalidate(K key) {
    _memory.remove(key);
  }

  @override
  void clear() {
    _memory.clear();
  }
}

class _Entry<V> {
  _Entry({required this.value, required this.expiresAt});

  final V value;
  final DateTime expiresAt;
}
