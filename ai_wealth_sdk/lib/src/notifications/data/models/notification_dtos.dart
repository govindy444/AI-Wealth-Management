import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Wire decoders for the notifications endpoints.
class NotificationDtos {
  const NotificationDtos._();

  static AppNotification fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as String?) ?? '',
        category: NotificationCategory.fromWire((j['category'] as String?) ?? 'alert'),
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        priority: NotificationPriority.fromWire((j['priority'] as String?) ?? 'normal'),
        createdAt:
            DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        read: (j['read'] as bool?) ?? false,
        route: j['route'] as String?,
      );

  static NotificationsPage pageFromJson(Map<String, dynamic> j) => NotificationsPage(
        items: (j['items'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(fromJson)
            .toList(growable: false),
        total: (j['total'] as num?)?.toInt() ?? 0,
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      );
}
