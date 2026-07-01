import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';
import '../dashboard/money.dart';


class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  final _amount = TextEditingController(text: '100000');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(recommendationsControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _applyAmount() {
    final v = double.tryParse(_amount.text.trim());
    if (v != null && v > 0) {
      ref.read(recommendationsControllerProvider.notifier).load(amount: v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationsControllerProvider);
    final notifier = ref.read(recommendationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Invest')),
      body: ResponsiveContainer(
        maxWidth: 640,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text('Your risk profile',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _ProfilePicker(
              selected: state.riskProfile,
              onSelect: notifier.selectProfile,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _applyAmount(),
                    decoration: const InputDecoration(
                      labelText: 'Amount to invest',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(onPressed: _applyAmount, child: const Text('Apply')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.isLoading && !state.hasData)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.status == RecommendationsStatus.error && !state.hasData)
              _Error(
                message: state.errorMessage ?? 'Could not load recommendations.',
                onRetry: notifier.load,
              )
            else if (state.recommendation != null)
              ..._results(context, state.recommendation!),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(BuildContext context, RecommendationSet set) {
    return [
      _StrategyCard(set: set),
      const SizedBox(height: AppSpacing.lg),
      Text('Suggested portfolio',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      ...set.recommendations.map((r) => _RecommendationCard(rec: r)),
    ];
  }
}

class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker({required this.selected, required this.onSelect});
  final RiskProfile selected;
  final ValueChanged<RiskProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final p in RiskProfile.values)
          ChoiceChip(
            label: Text(p.label),
            selected: p == selected,
            onSelected: (_) => onSelect(p),
          ),
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  const _StrategyCard({required this.set});
  final RecommendationSet set;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target return',
                style: text.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
            Text(
              '${(set.blendedExpectedReturn * 100).toStringAsFixed(1)}% p.a.',
              style: text.displaySmall?.copyWith(
                  color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(set.insight.summary,
                style: text.bodyMedium
                    ?.copyWith(color: scheme.onPrimaryContainer)),
            for (final a in set.insight.alternatives) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('• $a',
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onPrimaryContainer)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rec});
  final Recommendation rec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.product.name, style: text.titleSmall),
                      Text(
                        '${rec.product.type.label} · ${(rec.product.expectedReturn * 100).toStringAsFixed(1)}% p.a.',
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${rec.allocationPct.toStringAsFixed(0)}%',
                        style: text.titleMedium
                            ?.copyWith(color: scheme.primary)),
                    Text(formatInr(rec.suggestedAmount), style: text.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: (rec.allocationPct / 100).clamp(0.0, 1.0),
                minHeight: 8,
                color: scheme.primary,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                dense: true,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                leading: Icon(Icons.auto_awesome_rounded,
                    size: 18, color: scheme.primary),
                title: Text(
                  'Why this? · ${rec.rationale.confidencePercent}% confident',
                  style: text.labelMedium?.copyWith(color: scheme.primary),
                ),
                children: [
                  _bullets(context, 'Reasons', rec.rationale.reasons),
                  _bullets(context, 'Risks', rec.rationale.risks),
                  _bullets(context, 'Benefits', rec.rationale.benefits),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullets(BuildContext context, String label, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(label, style: text.labelSmall),
        ),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text('• $i', style: text.bodySmall),
            )),
      ],
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
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
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
