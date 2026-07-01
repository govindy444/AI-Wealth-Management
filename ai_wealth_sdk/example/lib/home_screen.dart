import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_screen.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
        title: const Text('My Wealth'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardControllerProvider.notifier).refresh(),
        child: _body(context, state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Ask AI advisor'),
      ),
    );
  }

  Widget _body(BuildContext context, DashboardState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final cs = Theme.of(context).colorScheme;

    if (state.status == DashboardStatus.error && !state.hasData) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 200),
          Icon(Icons.cloud_off_rounded, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? 'Could not load dashboard.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () =>
                  ref.read(dashboardControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final s = state.summary;
    if (s == null) return const SizedBox.shrink();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _NetWorthCard(summary: s),
        const SizedBox(height: 16),
        _InsightCard(insight: s.insight),
        const SizedBox(height: 16),
        Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final account in s.accounts) _AccountTile(account: account),
      ],
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final up = summary.isUp;
    final trendColor =
        up ? Colors.green.shade600 : cs.error;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi ${summary.fullName.split(' ').first}!',
              style: text.titleMedium?.copyWith(
                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatInr(summary.netWorth),
              style: text.displaySmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  up
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${up ? '+' : '-'}${_formatInr(summary.monthlyChange.abs())} this month',
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final Explanation insight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Text('AI insight', style: text.titleSmall),
                const Spacer(),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${insight.confidencePercent}% confident'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.summary, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: Icon(
            Icons.account_balance_outlined,
            color: cs.onSecondaryContainer,
          ),
        ),
        title: Text(account.name),
        subtitle: Text('•••• ${account.maskedNumber}'),
        trailing: Text(
          _formatInr(account.balance),
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

String _formatInr(double amount) {
  final abs = amount.abs();
  final prefix = amount < 0 ? '-₹' : '₹';
  if (abs >= 10000000) return '$prefix${(abs / 10000000).toStringAsFixed(2)} Cr';
  if (abs >= 100000) return '$prefix${(abs / 100000).toStringAsFixed(2)} L';
  if (abs >= 1000) return '$prefix${(abs / 1000).toStringAsFixed(1)} K';
  return '$prefix${abs.toStringAsFixed(0)}';
}
