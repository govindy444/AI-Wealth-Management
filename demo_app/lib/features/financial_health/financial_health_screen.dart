import 'dart:math' as math;

import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';


class FinancialHealthScreen extends ConsumerStatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  ConsumerState<FinancialHealthScreen> createState() =>
      _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends ConsumerState<FinancialHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(financialHealthControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialHealthControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Health')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(financialHealthControllerProvider.notifier).refresh(),
        child: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, FinancialHealthState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == HealthScoreStatus.error && !state.hasData) {
      return _ErrorView(
        message: state.errorMessage ?? 'Could not compute your score.',
        onRetry: () =>
            ref.read(financialHealthControllerProvider.notifier).refresh(),
      );
    }
    final health = state.health;
    if (health == null) return const SizedBox.shrink();

    return ResponsiveContainer(
      maxWidth: 640,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(child: _ScoreGauge(health: health)),
          const SizedBox(height: AppSpacing.lg),
          _InsightCard(insight: health.insight),
          const SizedBox(height: AppSpacing.xl),
          Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...health.byPriority.map((p) => _PillarCard(pillar: p)),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

Color healthColor(HealthStatus status) => switch (status) {
      HealthStatus.excellent => Colors.green,
      HealthStatus.good => Colors.lightGreen.shade700,
      HealthStatus.fair => Colors.amber.shade700,
      HealthStatus.poor => Colors.red,
    };

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.health});
  final FinancialHealth health;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = healthColor(health.status);
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _GaugePainter(
              progress: health.score / 100,
              color: color,
              track: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${health.score}',
                      style: text.displayMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: color)),
                  Text('out of 100', style: text.bodySmall),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Chip(
          backgroundColor: color.withValues(alpha: 0.15),
          label: Text(
            'Grade ${health.grade} · ${health.status.name[0].toUpperCase()}${health.status.name.substring(1)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color, required this.track});
  final double progress;
  final Color color;
  final Color track;

  static const _start = 135 * math.pi / 180;
  static const _sweep = 270 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    final stroke = 14.0;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, _start, _sweep, false, trackPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      _start,
      _sweep * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.pillar});
  final HealthPillar pillar;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = healthColor(pillar.status);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(pillar.label, style: text.titleSmall),
                const Spacer(),
                Text('${pillar.score}/100',
                    style: text.titleSmall?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: (pillar.score / 100).clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(pillar.detail, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: scheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    pillar.recommendation,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
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
                Text('What this means', style: text.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(insight.summary, style: text.bodyLarge),
            for (final a in insight.alternatives) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Next: $a',
                  style: text.bodyMedium?.copyWith(color: scheme.primary)),
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
