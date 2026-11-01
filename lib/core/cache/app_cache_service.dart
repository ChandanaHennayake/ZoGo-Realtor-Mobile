import 'package:flutter/foundation.dart';

/// Entry holding cached data and its expiry timestamp.
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// In-memory cache manager with TTL to eliminate unnecessary network round-trips
/// and deliver instant, flicker-free screen transitions.
class AppCacheService {
  static final AppCacheService _instance = AppCacheService._internal();
  factory AppCacheService() => _instance;
  static AppCacheService get instance => _instance;

  AppCacheService._internal();

  final Map<String, _CacheEntry<dynamic>> _store = {};

  /// Default durations
  static const Duration defaultTtl = Duration(minutes: 5);
  static const Duration masterDataTtl = Duration(hours: 1);
  static const Duration detailsTtl = Duration(minutes: 10);

  /// Retrieves an unexpired item from cache, or null if missing/expired.
  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _store.remove(key);
      debugPrint('[AppCacheService] Expired key removed: $key');
      return null;
    }

    if (entry.data is T) {
      debugPrint('[AppCacheService] CACHE HIT for: $key');
      return entry.data as T;
    }

    return null;
  }

  /// Stores data in cache with a defined TTL.
  void put<T>(String key, T data, {Duration? ttl}) {
    final expiry = DateTime.now().add(ttl ?? defaultTtl);
    _store[key] = _CacheEntry<T>(data: data, expiresAt: expiry);
    debugPrint('[AppCacheService] CACHE STORE: $key (expires in ${(ttl ?? defaultTtl).inSeconds}s)');
  }

  /// Checks if key exists and is not expired.
  bool contains(String key) {
    final entry = _store[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _store.remove(key);
      return false;
    }
    return true;
  }

  /// Removes an individual key.
  void invalidate(String key) {
    _store.remove(key);
    debugPrint('[AppCacheService] Invalidated: $key');
  }

  /// Removes all keys matching a prefix (e.g. 'properties_').
  void invalidatePrefix(String prefix) {
    _store.removeWhere((k, _) => k.startsWith(prefix));
    debugPrint('[AppCacheService] Invalidated prefix: $prefix');
  }

  /// Completely empties the cache (e.g. on logout).
  void clear() {
    _store.clear();
    debugPrint('[AppCacheService] Entire cache cleared.');
  }
}

