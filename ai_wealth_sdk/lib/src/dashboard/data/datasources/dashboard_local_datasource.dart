import 'dart:convert';

import '../../../core/error/exceptions.dart';
import '../../../core/storage/key_value_store.dart';
import '../models/dashboard_dto.dart';


abstract interface class DashboardLocalDataSource {
  Future<void> cache(DashboardDto dto);
  Future<DashboardDto?> readCached();
  Future<void> clear();
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  DashboardLocalDataSourceImpl(this._store);

  static const _key = 'dashboard.summary';
  final KeyValueStore _store;

  @override
  Future<void> cache(DashboardDto dto) async {
    try {
      await _store.setString(_key, jsonEncode(dto.toJson()));
    } catch (e) {
      throw CacheException('Failed to cache dashboard: $e');
    }
  }

  @override
  Future<DashboardDto?> readCached() async {
    try {
      final raw = await _store.getString(_key);
      if (raw == null) return null;
      return DashboardDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // Corrupt cache → treat as empty rather than crashing.
      throw CacheException('Failed to read cached dashboard: $e');
    }
  }

  @override
  Future<void> clear() => _store.remove(_key);
}
