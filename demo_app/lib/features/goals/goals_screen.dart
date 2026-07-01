import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';
import '../dashboard/money.dart';


class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(goalsControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlanner(context),
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Plan a goal'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(goalsControllerProvider.notifier).load(),
        child: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, GoalsState state) {
    if (state.isLoading && state.goals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == GoalsStatus.error && state.goals.isEmpty) {
      return _Error(
        message: state.errorMessage ?? 'Could not load goals.',
        onRetry: () => ref.read(goalsControllerProvider.notifier).load(),
      );
    }
    if (state.goals.isEmpty) {
      return _Empty(onPlan: () => _openPlanner(context));
    }
    return ResponsiveContainer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.sm),
          ...state.goals.map((g) => _GoalCard(goal: g)),
          const SizedBox(height: 80), // clear the FAB
        ],
      ),
    );
  }

  void _openPlanner(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const _PlannerSheet(),
      ),
    );
  }
}

IconData goalIcon(GoalCategory c) => switch (c) {
      GoalCategory.emergency => Icons.shield_outlined,
      GoalCategory.travel => Icons.flight_takeoff_outlined,
      GoalCategory.retirement => Icons.beach_access_outlined,
      GoalCategory.home => Icons.home_outlined,
      GoalCategory.car => Icons.directions_car_outlined,
      GoalCategory.education => Icons.school_outlined,
      GoalCategory.wealth => Icons.trending_up_rounded,
      GoalCategory.other => Icons.flag_outlined,
    };

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final progress = (goal.progressPct / 100).clamp(0.0, 1.0);
    final onTrackColor = goal.onTrack ? Colors.green.shade600 : scheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  child: Icon(goalIcon(goal.category),
                      color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: text.titleMedium),
                      Text(
                        '${goal.monthsRemaining} months left',
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: onTrackColor.withValues(alpha: 0.15),
                  label: Text(
                    goal.onTrack ? 'On track' : 'Behind',
                    style: TextStyle(color: onTrackColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: scheme.primary,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${formatInr(goal.currentAmount)} of ${formatInr(goal.targetAmount)}  ·  ${goal.progressPct.toStringAsFixed(0)}%',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!goal.onTrack)
              Text(
                'Contributing ${formatInr(goal.monthlyContribution)}/mo. Reach it by raising to about ${formatInr(goal.requiredMonthly)}/mo.',
                style: text.bodySmall?.copyWith(color: scheme.error),
              )
            else
              Text(
                'Contributing ${formatInr(goal.monthlyContribution)}/mo — projected ${formatInr(goal.projectedValue)}.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlannerSheet extends ConsumerStatefulWidget {
  const _PlannerSheet();

  @override
  ConsumerState<_PlannerSheet> createState() => _PlannerSheetState();
}

class _PlannerSheetState extends ConsumerState<_PlannerSheet> {
  final _target = TextEditingController(text: '1000000');
  final _years = TextEditingController(text: '5');
  final _current = TextEditingController(text: '100000');
  final _monthly = TextEditingController(text: '10000');
  GoalSimulation? _result;
  bool _busy = false;

  @override
  void dispose() {
    _target.dispose();
    _years.dispose();
    _current.dispose();
    _monthly.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final target = double.tryParse(_target.text.trim()) ?? 0;
    final years = double.tryParse(_years.text.trim()) ?? 1;
    final current = double.tryParse(_current.text.trim()) ?? 0;
    final monthly = double.tryParse(_monthly.text.trim());
    if (target <= 0) return;

    setState(() => _busy = true);
    final targetDate = DateTime.now().add(Duration(days: (years * 365).round()));
    final sim = await ref.read(goalsControllerProvider.notifier).simulate(
          SimulateGoalParams(
            targetAmount: target,
            targetDate: targetDate,
            currentAmount: current,
            monthlyContribution: monthly,
          ),
        );
    if (mounted) {
      setState(() {
        _result = sim;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Plan a goal', style: text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: _field(_target, 'Target (₹)')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _field(_years, 'Years')),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: _field(_current, 'Saved now (₹)')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _field(_monthly, 'Monthly (₹)')),
          ]),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _busy ? null : _run,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calculate'),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invest ${formatInr(_result!.requiredMonthly)}/month',
                    style: text.titleMedium
                        ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_result!.insight.summary, style: text.bodyMedium),
                  if (_result!.projectedValue != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _result!.onTrack
                          ? 'On track — projected ${formatInr(_result!.projectedValue!)}.'
                          : 'At your monthly amount you\'d reach ${formatInr(_result!.projectedValue!)}.',
                      style: text.bodySmall?.copyWith(
                        color: _result!.onTrack ? Colors.green.shade700 : scheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onPlan});
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        const Icon(Icons.flag_outlined, size: 48),
        const SizedBox(height: AppSpacing.md),
        Center(child: Text('No goals yet', style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: FilledButton.icon(
            onPressed: onPlan,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Plan a goal'),
          ),
        ),
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
