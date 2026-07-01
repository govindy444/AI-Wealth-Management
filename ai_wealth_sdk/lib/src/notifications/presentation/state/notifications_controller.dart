import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/use_case.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notifications_state.dart';

/// Drives the notification center: loads the feed and applies read/delete
/// actions optimistically (updating the list + unread badge in place).
class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController({
    required ListNotificationsUseCase list,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
    required DeleteNotificationUseCase delete,
  })  : _list = list,
        _markRead = markRead,
        _markAllRead = markAllRead,
        _delete = delete,
        super(const NotificationsState.initial());

  final ListNotificationsUseCase _list;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final DeleteNotificationUseCase _delete;

  Future<void> load() async {
    state = state.copyWith(status: NotificationsStatus.loading, clearError: true);
    final result = await _list(const ListNotificationsParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: failure.message,
      ),
      (page) => state.copyWith(
        status: NotificationsStatus.ready,
        items: page.items,
        unreadCount: page.unreadCount,
      ),
    );
  }

  Future<void> markRead(String id) async {
    final result = await _markRead(id);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {
        final wasUnread = state.items.any((n) => n.id == id && !n.read);
        state = state.copyWith(
          items: [
            for (final n in state.items)
              if (n.id == id) n.copyWith(read: true) else n,
          ],
          unreadCount: wasUnread
              ? (state.unreadCount - 1).clamp(0, state.unreadCount)
              : state.unreadCount,
        );
      },
    );
  }

  Future<void> markAllRead() async {
    final result = await _markAllRead(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) => state = state.copyWith(
        items: [for (final n in state.items) n.copyWith(read: true)],
        unreadCount: 0,
      ),
    );
  }

  Future<void> delete(String id) async {
    final result = await _delete(id);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {
        final removed = state.items.where((n) => n.id == id);
        final wasUnread = removed.isNotEmpty && !removed.first.read;
        state = state.copyWith(
          items: state.items.where((n) => n.id != id).toList(growable: false),
          unreadCount: wasUnread
              ? (state.unreadCount - 1).clamp(0, state.unreadCount)
              : state.unreadCount,
        );
      },
    );
  }

  Future<void> refresh() => load();
}
