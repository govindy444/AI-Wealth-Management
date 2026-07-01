import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';
import 'health_pillar.dart';

class FinancialHealth extends Equatable {
  const FinancialHealth({
    required this.score,
    required this.grade,
    required this.status,
    required this.pillars,
    required this.insight,
  });

  final int score; // 0–100
  final String grade; // A–E
  final HealthStatus status;
  final List<HealthPillar> pillars;
  final Explanation insight;

  List<HealthPillar> get byPriority =>
      [...pillars]..sort((a, b) => a.score.compareTo(b.score));

  @override
  List<Object?> get props => [score, grade, status, pillars, insight];
}
