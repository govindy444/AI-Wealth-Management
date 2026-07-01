import 'dart:math' as math;

import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';
import '../dashboard/money.dart';


class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(portfolioControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portfolioControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(portfolioControllerProvider.notifier).refresh(),
        child: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, PortfolioState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == PortfolioStatus.error && !state.hasData) {
      return _Error(
        message: state.errorMessage ?? 'Could not load your portfolio.',
        onRetry: () => ref.read(portfolioControllerProvider.notifier).refresh(),
      );
    }
    final s = state.summary;
    if (s == null) return const SizedBox.shrink();

    return ResponsiveContainer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ValueCard(summary: s),
          const SizedBox(height: AppSpacing.lg),
          _AllocationCard(summary: s),
          const SizedBox(height: AppSpacing.lg),
          _RiskCard(summary: s),
          const SizedBox(height: AppSpacing.lg),
          _InsightCard(insight: s.insight),
          const SizedBox(height: AppSpacing.xl),
          Text('Top holdings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...s.topHoldings.map((h) => _HoldingTile(holding: h)),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

Color assetColor(AssetClass c) => switch (c) {
      AssetClass.equity => const Color(0xFF3B82F6),
      AssetClass.debt => const Color(0xFF14B8A6),
      AssetClass.gold => const Color(0xFFF59E0B),
      AssetClass.cash => const Color(0xFF9CA3AF),
      AssetClass.realEstate => const Color(0xFF8B5E3C),
    };

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.summary});
  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final up = summary.isUp;
    final color = up ? Colors.green.shade600 : scheme.error;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Portfolio value',
                style: text.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
            Text(
              formatInr(summary.totalValue),
              style: text.displaySmall?.copyWith(
                  color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${up ? '+' : '-'}${formatInr(summary.totalGain.abs())} (${summary.gainPct.toStringAsFixed(1)}%) overall',
              style: text.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.summary});
  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asset allocation', style: text.titleSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutPainter(summary.allocation),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    children: [
                      for (final slice in summary.allocation)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: assetColor(slice.assetClass),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: Text(slice.assetClass.label,
                                  style: text.bodyMedium)),
                              Text('${slice.percentage.toStringAsFixed(0)}%',
                                  style: text.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
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

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices);
  final List<AllocationSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    var start = -math.pi / 2;
    final stroke = 18.0;
    for (final s in slices) {
      final sweep = s.percentage / 100 * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = assetColor(s.assetClass);
      canvas.drawArc(rect, start, sweep - 0.03, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices;
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.summary});
  final PortfolioSummary summary;

  Color _riskColor() => switch (summary.riskLabel) {
        RiskLabel.high => Colors.red,
        RiskLabel.moderate => Colors.amber.shade700,
        RiskLabel.low => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = _riskColor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Risk meter', style: text.titleSmall),
                const Spacer(),
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: color.withValues(alpha: 0.15),
                  label: Text('${summary.riskLabel.label} (${summary.riskScore})',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: (summary.riskScore / 100).clamp(0.0, 1.0),
                minHeight: 10,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Diversification: ${summary.diversificationScore}/100',
                style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile({required this.holding});
  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final up = holding.isUp;
    final color = up ? Colors.green.shade600 : scheme.error;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: assetColor(holding.assetClass).withValues(alpha: 0.2),
          child: Icon(Icons.pie_chart_rounded, color: assetColor(holding.assetClass)),
        ),
        title: Text(holding.name),
        subtitle: Text(holding.assetClass.label),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatInr(holding.currentValue),
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            Text('${up ? '+' : ''}${holding.gainPct.toStringAsFixed(1)}%',
                style: text.labelSmall?.copyWith(color: color)),
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
              Text('Insight', style: text.titleSmall),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(insight.summary, style: text.bodyLarge),
            for (final a in insight.alternatives) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('• $a',
                  style: text.bodyMedium?.copyWith(color: scheme.primary)),
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
