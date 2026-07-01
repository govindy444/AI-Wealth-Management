import '../../../core/network/api_client.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_dtos.dart';

/// Talks to the backend `/notifications` endpoints via the [ApiClient].
abstract interface class NotificationRemoteDataSource {
  Future<NotificationsPage> list({bool unreadOnly, int limit, int offset});
  Future<int> unreadCount();
  Future<AppNotification> markRead(String id);
  Future<int> markAllRead();
  Future<void> delete(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<NotificationsPage> list({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _client.get('/notifications', queryParameters: {
      'unread_only': unreadOnly,
      'limit': limit,
      'offset': offset,
    });
    return NotificationDtos.pageFromJson(res.asMap);
  }

  @override
  Future<int> unreadCount() async {
    final res = await _client.get('/notifications/unread-count');
    return (res.asMap['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<AppNotification> markRead(String id) async {
    final res = await _client.post('/notifications/$id/read');
    return NotificationDtos.fromJson(res.asMap);
  }

  @override
  Future<int> markAllRead() async {
    final res = await _client.post('/notifications/read-all');
    return (res.asMap['updated'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> delete(String id) => _client.delete('/notifications/$id');
}
