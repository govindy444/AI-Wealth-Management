import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/notifications/data/models/notification_dtos.dart';
import 'package:ai_wealth_sdk/src/notifications/data/repositories/notification_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _ntf(String id, {bool read = false, String cat = 'security'}) => {
      'id': id,
      'category': cat,
      'title': 'Title $id',
      'body': 'Body $id',
      'priority': 'high',
      'created_at': '2026-06-29T10:00:00Z',
      'read': read,
      'route': '/fraud-alerts',
    };

Map<String, dynamic> _pageJson() => {
      'items': [_ntf('ntf_000'), _ntf('ntf_001'), _ntf('ntf_002', read: true)],
      'total': 3,
      'unread_count': 2,
    };

void main() {
  group('NotificationDtos', () {
    test('decodes a page with unread count', () {
      final page = NotificationDtos.pageFromJson(_pageJson());
      expect(page.total, 3);
      expect(page.unreadCount, 2);
      expect(page.items.first.category, NotificationCategory.security);
      expect(page.items.first.route, '/fraud-alerts');
      expect(page.items.last.read, isTrue);
    });
  });

  group('NotificationsController', () {
    NotificationsController controller(FakeRemote remote) {
      final repo = NotificationRepositoryImpl(remote: remote, logger: _logger);
      return NotificationsController(
        list: ListNotificationsUseCase(repo),
        markRead: MarkNotificationReadUseCase(repo),
        markAllRead: MarkAllNotificationsReadUseCase(repo),
        delete: DeleteNotificationUseCase(repo),
      );
    }

    test('load populates items and unread count', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, NotificationsStatus.ready);
      expect(c.state.items, hasLength(3));
      expect(c.state.unreadCount, 2);
    });

    test('markRead updates the item and decrements unread in place', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();

      await c.markRead('ntf_000');

      expect(c.state.items.firstWhere((n) => n.id == 'ntf_000').read, isTrue);
      expect(c.state.unreadCount, 1);
    });

    test('markAllRead zeroes the count and marks every item read', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();

      await c.markAllRead();

      expect(c.state.unreadCount, 0);
      expect(c.state.items.every((n) => n.read), isTrue);
    });

    test('delete removes the item and adjusts unread', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();

      await c.delete('ntf_000'); // was unread

      expect(c.state.items.any((n) => n.id == 'ntf_000'), isFalse);
      expect(c.state.unreadCount, 1);
    });

    test('surfaces an error on load failure', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, NotificationsStatus.error);
    });
  });
}

class FakeRemote implements NotificationRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  @override
  Future<NotificationsPage> list({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    if (_fail) throw NetworkException('offline');
    return NotificationDtos.pageFromJson(_pageJson());
  }

  @override
  Future<int> unreadCount() async => 2;

  @override
  Future<AppNotification> markRead(String id) async =>
      NotificationDtos.fromJson(_ntf(id, read: true));

  @override
  Future<int> markAllRead() async => 2;

  @override
  Future<void> delete(String id) async {}
}
