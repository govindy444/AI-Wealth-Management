import 'package:equatable/equatable.dart';

import '../../domain/entities/budget.dart';
import '../../domain/entities/spending_summary.dart';

enum SpendingStatus { initial, loading, ready, error }

/// Immutable state for the spending analytics screen.
class SpendingState extends Equatable {
  const SpendingState({
    this.status = SpendingStatus.initial,
    this.summary,
    this.budgets = const [],
    this.errorMessage,
  });

  final SpendingStatus status;
  final SpendingSummary? summary;
  final List<Budget> budgets;
  final String? errorMessage;

  const SpendingState.initial() : this();

  bool get isLoading => status == SpendingStatus.loading;
  bool get hasData => summary != null;

  SpendingState copyWith({
    SpendingStatus? status,
    SpendingSummary? summary,
    List<Budget>? budgets,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SpendingState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      budgets: budgets ?? this.budgets,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, summary, budgets, errorMessage];
}
