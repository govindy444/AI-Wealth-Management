import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';


class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(notificationsControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final notifier = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.hasUnread)
            TextButton(
              onPressed: notifier.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: _body(context, state, notifier),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    NotificationsState state,
    NotificationsController notifier,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == NotificationsStatus.error && state.items.isEmpty) {
      return _Error(
        message: state.errorMessage ?? 'Could not load notifications.',
        onRetry: notifier.load,
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          const Icon(Icons.notifications_off_outlined, size: 48),
          const SizedBox(height: AppSpacing.md),
          Center(child: Text("You're all caught up",
              style: Theme.of(context).textTheme.titleMedium)),
        ],
      );
    }

    return ResponsiveContainer(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: state.items.length,
        itemBuilder: (context, i) => _NotificationTile(
          notification: state.items[i],
          onTap: () {
            final n = state.items[i];
            notifier.markRead(n.id);
            if (n.route != null) context.push(n.route!);
          },
          onDismiss: () => notifier.delete(state.items[i].id),
        ),
      ),
    );
  }
}

IconData categoryIcon(NotificationCategory c) => switch (c) {
      NotificationCategory.security => Icons.shield_outlined,
      NotificationCategory.alert => Icons.warning_amber_rounded,
      NotificationCategory.reminder => Icons.event_outlined,
      NotificationCategory.insight => Icons.auto_awesome_rounded,
      NotificationCategory.goal => Icons.flag_outlined,
      NotificationCategory.transaction => Icons.receipt_long_outlined,
      NotificationCategory.promo => Icons.campaign_outlined,
    };

Color categoryColor(NotificationCategory c, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (c) {
    NotificationCategory.security => Colors.red,
    NotificationCategory.alert => Colors.amber.shade700,
    NotificationCategory.reminder => Colors.blue,
    NotificationCategory.goal => Colors.green,
    NotificationCategory.promo => Colors.purple,
    _ => scheme.primary,
  };
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = categoryColor(notification.category, context);
    final unread = !notification.read;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: scheme.errorContainer,
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Container(
        color: unread ? scheme.primary.withValues(alpha: 0.05) : null,
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(categoryIcon(notification.category), color: color),
          ),
          title: Text(
            notification.title,
            style: text.titleSmall?.copyWith(
              fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          subtitle: Text(notification.body),
          trailing: unread
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
        const Icon(Icons.cloud_off_rounded, size: 48),
        const SizedBox(height: AppSpacing.md),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
