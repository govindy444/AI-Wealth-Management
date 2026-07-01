import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router/app_routes.dart';
import '../../app/theme/app_spacing.dart';
import 'money.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(dashboardControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading
                ? null
                : () => ref.read(dashboardControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: AppRoutes.financialHealth,
                child: ListTile(
                  leading: Icon(Icons.favorite_border),
                  title: Text('Financial health'),
                ),
              ),
              PopupMenuItem(
                value: AppRoutes.predictive,
                child: ListTile(
                  leading: Icon(Icons.query_stats_rounded),
                  title: Text('Forecast'),
                ),
              ),
              PopupMenuItem(
                value: AppRoutes.fraudAlerts,
                child: ListTile(
                  leading: Icon(Icons.shield_outlined),
                  title: Text('Fraud & safety'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
        child: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, DashboardState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == DashboardStatus.error && !state.hasData) {
      return _ErrorView(
        message: state.errorMessage ?? 'Could not load your dashboard.',
        onRetry: () => ref.read(dashboardControllerProvider.notifier).refresh(),
      );
    }

    final summary = state.summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return ResponsiveContainer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _NetWorthCard(summary: summary),
          const SizedBox(height: AppSpacing.lg),
          _InsightCard(insight: summary.insight),
          const SizedBox(height: AppSpacing.xl),
          Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...summary.accounts.map((a) => _AccountTile(account: a)),
          const SizedBox(height: AppSpacing.xl),
          Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const _QuickActions(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final up = summary.isUp;
    final trendColor = up ? Colors.green.shade600 : scheme.error;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi ${summary.fullName.split(' ').first}, your net worth',
              style: text.bodyMedium
                  ?.copyWith(color: scheme.onPrimaryContainer.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatInrCompact(summary.netWorth),
              style: text.displaySmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 18,
                  color: trendColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${up ? '+' : '-'}${formatInr(summary.monthlyChange.abs())} this month',
                  style: text.bodyMedium?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _Metric(
                  label: 'Assets',
                  value: formatInrCompact(summary.totalAssets),
                ),
                const SizedBox(width: AppSpacing.xl),
                _Metric(
                  label: 'Liabilities',
                  value: formatInrCompact(summary.totalLiabilities),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall
              ?.copyWith(color: scheme.onPrimaryContainer.withValues(alpha: 0.7)),
        ),
        Text(
          value,
          style: text.titleMedium?.copyWith(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final Explanation insight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('AI insight', style: text.titleSmall),
                const Spacer(),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${insight.confidencePercent}% confident'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(insight.summary, style: text.bodyLarge),
            if (insight.reasons.isNotEmpty ||
                insight.risks.isNotEmpty ||
                insight.alternatives.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  title: Text('Why this?', style: text.labelLarge),
                  children: [
                    _Bullets(label: 'Reasons', items: insight.reasons),
                    _Bullets(label: 'Risks', items: insight.risks),
                    _Bullets(label: 'Alternatives', items: insight.alternatives),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.label, required this.items});
  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            label,
            style: text.labelMedium?.copyWith(color: scheme.primary),
          ),
        ),
        ...items.map(
          (i) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: text.bodyMedium),
                Expanded(child: Text(i, style: text.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});
  final Account account;

  IconData get _icon => switch (account.type) {
        AccountType.savings => Icons.savings_outlined,
        AccountType.current => Icons.account_balance_wallet_outlined,
        AccountType.deposit => Icons.lock_clock_outlined,
        AccountType.mutualFund => Icons.show_chart_rounded,
        AccountType.creditCard => Icons.credit_card_rounded,
        AccountType.loan => Icons.home_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final changeUp = account.monthlyChange >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(_icon, color: scheme.onSecondaryContainer),
        ),
        title: Text(account.name),
        subtitle: Text('•••• ${account.maskedNumber}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              account.isLiability
                  ? '- ${formatInr(account.balance)}'
                  : formatInr(account.balance),
              style: text.titleSmall?.copyWith(
                color: account.isLiability ? scheme.error : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${changeUp ? '+' : '-'}${formatInr(account.monthlyChange.abs())}',
              style: text.labelSmall?.copyWith(
                color: changeUp ? Colors.green.shade600 : scheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, String)>[
      (Icons.auto_awesome_rounded, 'Ask AI', AppRoutes.chat),
      (Icons.flag_outlined, 'Goals', AppRoutes.goals),
      (Icons.recommend_outlined, 'Invest', AppRoutes.recommendations),
      (Icons.pie_chart_rounded, 'Spending', AppRoutes.spending),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (icon, label, route) in actions)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: _QuickAction(
                icon: icon,
                label: label,
                onTap: () => route == AppRoutes.spending
                    ? context.go(route)
                    : context.push(route),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
        Icon(Icons.cloud_off_rounded, size: 48, color: scheme.onSurfaceVariant),
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
