import 'package:equatable/equatable.dart';

import '../../domain/entities/goal.dart';

enum GoalsStatus { initial, loading, ready, error }

/// Immutable state for the goals screen.
class GoalsState extends Equatable {
  const GoalsState({
    this.status = GoalsStatus.initial,
    this.goals = const [],
    this.errorMessage,
  });

  final GoalsStatus status;
  final List<Goal> goals;
  final String? errorMessage;

  const GoalsState.initial() : this();

  bool get isLoading => status == GoalsStatus.loading;

  GoalsState copyWith({
    GoalsStatus? status,
    List<Goal>? goals,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoalsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, goals, errorMessage];
}
