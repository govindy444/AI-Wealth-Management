import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/notification_remote_datasource.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/usecases/notification_usecases.dart';
import 'presentation/state/notifications_controller.dart';
import 'presentation/state/notifications_state.dart';

/// DI wiring for the Notifications module (Module 18).
/// A pure consumer of the foundation (remote datasource uses `apiClientProvider`).

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>(
  (ref) => NotificationRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    remote: ref.watch(notificationRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final listNotificationsUseCaseProvider =
    Provider((ref) => ListNotificationsUseCase(ref.watch(notificationRepositoryProvider)));
final getUnreadCountUseCaseProvider =
    Provider((ref) => GetUnreadCountUseCase(ref.watch(notificationRepositoryProvider)));
final markNotificationReadUseCaseProvider = Provider(
    (ref) => MarkNotificationReadUseCase(ref.watch(notificationRepositoryProvider)));
final markAllNotificationsReadUseCaseProvider = Provider(
    (ref) => MarkAllNotificationsReadUseCase(ref.watch(notificationRepositoryProvider)));
final deleteNotificationUseCaseProvider =
    Provider((ref) => DeleteNotificationUseCase(ref.watch(notificationRepositoryProvider)));

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>(
  (ref) => NotificationsController(
    list: ref.watch(listNotificationsUseCaseProvider),
    markRead: ref.watch(markNotificationReadUseCaseProvider),
    markAllRead: ref.watch(markAllNotificationsReadUseCaseProvider),
    delete: ref.watch(deleteNotificationUseCaseProvider),
  ),
);
