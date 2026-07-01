import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class ListNotificationsParams extends Equatable {
  const ListNotificationsParams({this.unreadOnly = false, this.limit = 50, this.offset = 0});
  final bool unreadOnly;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [unreadOnly, limit, offset];
}

class ListNotificationsUseCase
    implements UseCase<NotificationsPage, ListNotificationsParams> {
  ListNotificationsUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  FutureResult<NotificationsPage> call(ListNotificationsParams p) =>
      _repository.list(unreadOnly: p.unreadOnly, limit: p.limit, offset: p.offset);
}

class GetUnreadCountUseCase implements UseCase<int, NoParams> {
  GetUnreadCountUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  FutureResult<int> call(NoParams params) => _repository.unreadCount();
}

class MarkNotificationReadUseCase implements UseCase<AppNotification, String> {
  MarkNotificationReadUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  FutureResult<AppNotification> call(String id) => _repository.markRead(id);
}

class MarkAllNotificationsReadUseCase implements UseCase<int, NoParams> {
  MarkAllNotificationsReadUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  FutureResult<int> call(NoParams params) => _repository.markAllRead();
}

class DeleteNotificationUseCase implements UseCase<void, String> {
  DeleteNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  @override
  FutureResult<void> call(String id) => _repository.delete(id);
}
