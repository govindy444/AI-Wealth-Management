import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';
import '../dashboard/money.dart';


class SpendingScreen extends ConsumerStatefulWidget {
  const SpendingScreen({super.key});

  @override
  ConsumerState<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends ConsumerState<SpendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(spendingControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spendingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Spending')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(spendingControllerProvider.notifier).refresh(),
        child: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, SpendingState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == SpendingStatus.error && !state.hasData) {
      return _ErrorView(
        message: state.errorMessage ?? 'Could not load spending.',
        onRetry: () => ref.read(spendingControllerProvider.notifier).refresh(),
      );
    }
    final summary = state.summary;
    if (summary == null) return const SizedBox.shrink();

    return ResponsiveContainer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _SummaryCard(summary: summary),
          const SizedBox(height: AppSpacing.lg),
          _InsightCard(insight: summary.insight),
          const SizedBox(height: AppSpacing.xl),
          Text('By category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...summary.categories.map((c) => _CategoryBar(spend: c)),
          if (state.budgets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Budgets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...state.budgets.map((b) => _BudgetTile(
                  budget: b,
                  onEdit: () => _editBudget(context, b),
                )),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _editBudget(BuildContext context, Budget budget) async {
    final controller =
        TextEditingController(text: budget.monthlyLimit.toStringAsFixed(0));
    final newLimit = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${budget.category.label} budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '₹ ',
            labelText: 'Monthly limit',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, (v != null && v > 0) ? v : null);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newLimit != null) {
      await ref
          .read(spendingControllerProvider.notifier)
          .setBudget(budget.category, newLimit);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final SpendingSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final up = summary.isUp;
    final trendColor = up ? scheme.error : Colors.green.shade600;

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spent this month', style: text.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatInr(summary.totalSpent),
              style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
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
                  '${summary.changePct.abs().toStringAsFixed(0)}% vs last month',
                  style: text.bodyMedium
                      ?.copyWith(color: trendColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _mini(context, 'Income', formatInr(summary.totalIncome)),
                _mini(context, 'Net', formatInr(summary.net)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(BuildContext context, String label, String value) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        Text(value, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.spend});
  final CategorySpend spend;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = categoryColor(spend.category, context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(categoryIcon(spend.category), size: 18, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(spend.category.label, style: text.bodyMedium),
              const Spacer(),
              Text(
                '${formatInr(spend.amount)}  ·  ${spend.percentage.toStringAsFixed(0)}%',
                style: text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (spend.percentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({required this.budget, required this.onEdit});
  final Budget budget;
  final VoidCallback onEdit;

  Color _statusColor(BuildContext context) => switch (budget.status) {
        BudgetStatus.over => Theme.of(context).colorScheme.error,
        BudgetStatus.near => Colors.amber.shade700,
        BudgetStatus.under => Colors.green.shade600,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = _statusColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(budget.category.label, style: text.bodyMedium),
              const SizedBox(width: AppSpacing.sm),
              if (budget.status == BudgetStatus.over)
                Icon(Icons.warning_amber_rounded, size: 16, color: color),
              const Spacer(),
              Text(
                '${formatInr(budget.spent)} / ${formatInr(budget.monthlyLimit)}',
                style: text.bodySmall,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (budget.usedPct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
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
                Text('Insight', style: text.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(insight.summary, style: text.bodyLarge),
            for (final r in insight.reasons) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('• $r', style: text.bodyMedium),
            ],
            for (final r in insight.risks) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('• $r',
                  style: text.bodyMedium?.copyWith(color: scheme.error)),
            ],
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

Color categoryColor(SpendCategory c, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return switch (c) {
    SpendCategory.groceries => Colors.green,
    SpendCategory.dining => Colors.orange,
    SpendCategory.transport => Colors.blue,
    SpendCategory.utilities => Colors.teal,
    SpendCategory.shopping => Colors.purple,
    SpendCategory.entertainment => Colors.pink,
    SpendCategory.health => Colors.red,
    SpendCategory.rent => Colors.brown,
    _ => scheme.primary,
  };
}

IconData categoryIcon(SpendCategory c) => switch (c) {
      SpendCategory.groceries => Icons.local_grocery_store_outlined,
      SpendCategory.dining => Icons.restaurant_outlined,
      SpendCategory.transport => Icons.directions_car_outlined,
      SpendCategory.utilities => Icons.bolt_outlined,
      SpendCategory.shopping => Icons.shopping_bag_outlined,
      SpendCategory.entertainment => Icons.movie_outlined,
      SpendCategory.health => Icons.favorite_border,
      SpendCategory.rent => Icons.home_outlined,
      _ => Icons.category_outlined,
    };
