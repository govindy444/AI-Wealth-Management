import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

/// Coordinates the notifications API, mapping transport exceptions to [Failure]s
/// via [BaseRepository.guard].
class NotificationRepositoryImpl
    with BaseRepository
    implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final NotificationRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<NotificationsPage> list({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) =>
      guard(() => _remote.list(unreadOnly: unreadOnly, limit: limit, offset: offset));

  @override
  FutureResult<int> unreadCount() => guard(() => _remote.unreadCount());

  @override
  FutureResult<AppNotification> markRead(String id) =>
      guard(() => _remote.markRead(id));

  @override
  FutureResult<int> markAllRead() => guard(() => _remote.markAllRead());

  @override
  FutureResult<void> delete(String id) => guard(() => _remote.delete(id));
}
