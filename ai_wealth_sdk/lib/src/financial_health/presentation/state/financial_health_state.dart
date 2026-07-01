import 'package:equatable/equatable.dart';

import '../../domain/entities/financial_health.dart';

enum HealthScoreStatus { initial, loading, ready, error }

class FinancialHealthState extends Equatable {
  const FinancialHealthState({
    this.status = HealthScoreStatus.initial,
    this.health,
    this.errorMessage,
  });

  final HealthScoreStatus status;
  final FinancialHealth? health;
  final String? errorMessage;

  const FinancialHealthState.initial() : this();

  bool get isLoading => status == HealthScoreStatus.loading;
  bool get hasData => health != null;

  FinancialHealthState copyWith({
    HealthScoreStatus? status,
    FinancialHealth? health,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FinancialHealthState(
      status: status ?? this.status,
      health: health ?? this.health,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, health, errorMessage];
}
