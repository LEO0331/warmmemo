abstract class CacheStore<K, V> {
  V? get(K key);

  bool hasValid(K key);

  void set(K key, V value, {Duration? ttl});

  void invalidate(K key);

  void clear();
}
