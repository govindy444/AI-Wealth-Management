import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/features/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _ntf(String id, {bool read = false}) => AppNotification(
      id: id,
      category: NotificationCategory.security,
      title: 'Title $id',
      body: 'Body $id',
      priority: NotificationPriority.high,
      createdAt: DateTime(2026, 6, 29),
      read: read,
      route: null,
    );

class _FakeRepo implements NotificationRepository {
  int markAllCalls = 0;

  @override
  Future<Result<NotificationsPage>> list({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async =>
      success(NotificationsPage(
        items: [_ntf('ntf_000'), _ntf('ntf_001', read: true)],
        total: 2,
        unreadCount: 1,
      ));

  @override
  Future<Result<int>> unreadCount() async => success(1);

  @override
  Future<Result<AppNotification>> markRead(String id) async =>
      success(_ntf(id, read: true));

  @override
  Future<Result<int>> markAllRead() async {
    markAllCalls++;
    return success(1);
  }

  @override
  Future<Result<void>> delete(String id) async => success(null);
}

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists notifications and shows mark-all-read when unread',
      (tester) async {
    await _pump(tester, _FakeRepo());
    expect(find.text('Title ntf_000'), findsOneWidget);
    expect(find.text('Title ntf_001'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('mark all read clears the badge and hides the action',
      (tester) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(repo.markAllCalls, 1);
    expect(find.text('Mark all read'), findsNothing); // no unread left
  });
}
