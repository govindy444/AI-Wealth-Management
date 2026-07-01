import 'package:equatable/equatable.dart';

enum GoalCategory {
  emergency,
  travel,
  retirement,
  home,
  car,
  education,
  wealth,
  other;

  String get wire => name;

  static GoalCategory fromWire(String value) => GoalCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => GoalCategory.other,
      );

  String get label => switch (this) {
        GoalCategory.emergency => 'Emergency',
        GoalCategory.travel => 'Travel',
        GoalCategory.retirement => 'Retirement',
        GoalCategory.home => 'Home',
        GoalCategory.car => 'Car',
        GoalCategory.education => 'Education',
        GoalCategory.wealth => 'Wealth',
        GoalCategory.other => 'Other',
      };
}

/// A savings/investment goal with its computed projection (from the backend).
class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.name,
    required this.category,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.monthlyContribution,
    required this.expectedReturnRate,
    required this.progressPct,
    required this.monthsRemaining,
    required this.requiredMonthly,
    required this.projectedValue,
    required this.onTrack,
    required this.surplusOrShortfall,
  });

  final String id;
  final String name;
  final GoalCategory category;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final double monthlyContribution;
  final double expectedReturnRate;

  // Computed projections from the backend:
  final double progressPct;
  final int monthsRemaining;
  final double requiredMonthly;
  final double projectedValue;
  final bool onTrack;
  final double surplusOrShortfall;

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        targetAmount,
        currentAmount,
        targetDate,
        monthlyContribution,
        expectedReturnRate,
        progressPct,
        monthsRemaining,
        requiredMonthly,
        projectedValue,
        onTrack,
        surplusOrShortfall,
      ];
}
