import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';
import '../dashboard/money.dart';


class PredictiveScreen extends ConsumerStatefulWidget {
  const PredictiveScreen({super.key});

  @override
  ConsumerState<PredictiveScreen> createState() => _PredictiveScreenState();
}

class _PredictiveScreenState extends ConsumerState<PredictiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(predictiveControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictiveControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Forecast')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(predictiveControllerProvider.notifier).refresh(),
        child: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, PredictiveState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == PredictiveStatus.error && !state.hasData) {
      return _Error(
        message: state.errorMessage ?? 'Could not load your forecast.',
        onRetry: () => ref.read(predictiveControllerProvider.notifier).refresh(),
      );
    }
    final f = state.forecast;
    if (f == null) return const SizedBox.shrink();

    return ResponsiveContainer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _BalanceCard(forecast: f),
          const SizedBox(height: AppSpacing.lg),
          _InsightCard(insight: f.insight),
          const SizedBox(height: AppSpacing.xl),
          Text("What's coming up",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...f.predictions.map((p) => _PredictionTile(prediction: p)),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

IconData _icon(PredictionType t) => switch (t) {
      PredictionType.salaryCredit => Icons.payments_outlined,
      PredictionType.billDue => Icons.receipt_long_outlined,
      PredictionType.emiDue => Icons.home_outlined,
      PredictionType.lowBalance => Icons.warning_amber_rounded,
      PredictionType.taxReminder => Icons.account_balance_outlined,
    };

Color _severityColor(PredictionSeverity s, BuildContext context) => switch (s) {
      PredictionSeverity.critical => Theme.of(context).colorScheme.error,
      PredictionSeverity.warning => Colors.amber.shade700,
      PredictionSeverity.info => Theme.of(context).colorScheme.primary,
    };

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.forecast});
  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final down = forecast.projectedMonthEndBalance < forecast.currentLiquidBalance;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available now', style: text.bodySmall),
                  Text(formatInr(forecast.currentLiquidBalance),
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Icon(down ? Icons.east_rounded : Icons.east_rounded,
                color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Projected month-end', style: text.bodySmall),
                  Text(
                    formatInr(forecast.projectedMonthEndBalance),
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: down ? scheme.error : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionTile extends StatelessWidget {
  const _PredictionTile({required this.prediction});
  final Prediction prediction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = _severityColor(prediction.severity, context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_icon(prediction.type), color: color),
        ),
        title: Text(prediction.title),
        subtitle: Text(prediction.message),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (prediction.amount != null)
              Text(formatInr(prediction.amount!.abs()),
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            Text(
              prediction.daysAway <= 0
                  ? 'today'
                  : 'in ${prediction.daysAway}d',
              style: text.labelSmall,
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Outlook', style: text.titleSmall),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(insight.summary, style: text.bodyLarge),
            for (final r in insight.reasons) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('• $r', style: text.bodyMedium),
            ],
            for (final r in insight.risks) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('• $r', style: text.bodyMedium?.copyWith(color: scheme.error)),
            ],
          ],
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
