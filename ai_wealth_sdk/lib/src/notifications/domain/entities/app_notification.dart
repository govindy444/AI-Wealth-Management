import 'package:equatable/equatable.dart';

enum NotificationCategory {
  security,
  alert,
  reminder,
  insight,
  goal,
  transaction,
  promo;

  static NotificationCategory fromWire(String value) =>
      NotificationCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => NotificationCategory.alert,
      );
}

enum NotificationPriority {
  low,
  normal,
  high;

  static NotificationPriority fromWire(String value) => switch (value) {
        'high' => NotificationPriority.high,
        'low' => NotificationPriority.low,
        _ => NotificationPriority.normal,
      };
}

/// A unified notification. (Named `AppNotification` to avoid colliding with
/// Flutter's framework `Notification` class.)
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.priority,
    required this.createdAt,
    required this.read,
    this.route,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool read;

  /// Optional in-app deep link to open on tap.
  final String? route;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        category: category,
        title: title,
        body: body,
        priority: priority,
        createdAt: createdAt,
        read: read ?? this.read,
        route: route,
      );

  @override
  List<Object?> get props =>
      [id, category, title, body, priority, createdAt, read, route];
}
