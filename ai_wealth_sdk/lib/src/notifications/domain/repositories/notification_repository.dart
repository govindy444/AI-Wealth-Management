import '../../../core/utils/result.dart';
import '../entities/app_notification.dart';

/// A page of notifications plus the unread badge count.
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int total;
  final int unreadCount;
}

/// Notifications repository contract.
abstract interface class NotificationRepository {
  FutureResult<NotificationsPage> list({bool unreadOnly = false, int limit = 50, int offset = 0});
  FutureResult<int> unreadCount();
  FutureResult<AppNotification> markRead(String id);
  FutureResult<int> markAllRead();
  FutureResult<void> delete(String id);
}
