import 'package:equatable/equatable.dart';

import '../../domain/entities/app_notification.dart';

enum NotificationsStatus { initial, loading, ready, error }

/// Immutable state for the notification center.
class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final int unreadCount;
  final String? errorMessage;

  const NotificationsState.initial() : this();

  bool get isLoading => status == NotificationsStatus.loading;
  bool get hasUnread => unreadCount > 0;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, items, unreadCount, errorMessage];
}
