import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';
import '../dashboard/money.dart';


class FraudScreen extends ConsumerStatefulWidget {
  const FraudScreen({super.key});

  @override
  ConsumerState<FraudScreen> createState() => _FraudScreenState();
}

class _FraudScreenState extends ConsumerState<FraudScreen> {
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(fraudControllerProvider.notifier).loadAlerts(),
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fraudControllerProvider);
    final notifier = ref.read(fraudControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Fraud & Safety')),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ResponsiveContainer(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: AppSpacing.lg),
              _MessageChecker(
                controller: _message,
                checking: state.checking,
                result: state.messageCheck,
                onCheck: () => notifier.checkMessage(_message.text),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (state.isLoading && !state.hasData)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == FraudStatus.error && !state.hasData)
                _Error(
                  message: state.errorMessage ?? 'Could not load alerts.',
                  onRetry: notifier.loadAlerts,
                )
              else if (state.report != null)
                ..._alerts(context, state.report!),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _alerts(BuildContext context, FraudAlerts report) {
    final scheme = Theme.of(context).colorScheme;
    return [
      Card(
        color: report.hasAlerts
            ? scheme.errorContainer.withValues(alpha: 0.4)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                report.hasAlerts ? Icons.gpp_maybe_outlined : Icons.verified_user_outlined,
                color: report.hasAlerts ? scheme.error : Colors.green,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(report.insight.summary,
                  style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      ...report.alerts.map((a) => _AlertTile(alert: a)),
    ];
  }
}

Color riskColor(FraudRiskLevel r) => switch (r) {
      FraudRiskLevel.high => Colors.red,
      FraudRiskLevel.medium => Colors.amber.shade700,
      FraudRiskLevel.low => Colors.green,
    };

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final FraudAlert alert;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = riskColor(alert.riskLevel);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 18, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(alert.merchant, style: text.titleSmall)),
                Text(formatInr(alert.amount),
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: color.withValues(alpha: 0.15),
                  label: Text('${alert.riskLevel.label} risk · ${alert.type.label}',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(alert.reason, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MessageChecker extends StatelessWidget {
  const _MessageChecker({
    required this.controller,
    required this.checking,
    required this.result,
    required this.onCheck,
  });

  final TextEditingController controller;
  final bool checking;
  final MessageCheck? result;
  final VoidCallback onCheck;

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
              Icon(Icons.policy_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Is this message a scam?', style: text.titleSmall),
            ]),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Paste a suspicious SMS or email…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: checking ? null : onCheck,
                icon: checking
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search_rounded),
                label: const Text('Check'),
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _CheckResult(result: result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckResult extends StatelessWidget {
  const _CheckResult({required this.result});
  final MessageCheck result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = riskColor(result.riskLevel);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(result.isSafe ? Icons.check_circle_outline : Icons.dangerous_outlined,
                  color: color),
              const SizedBox(width: AppSpacing.sm),
              Text('${result.riskLevel.label} risk (${result.score}/100)',
                  style: text.titleSmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(result.explanation.summary, style: text.bodyMedium),
          for (final r in result.explanation.reasons) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('• $r', style: text.bodySmall),
          ],
        ],
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
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
