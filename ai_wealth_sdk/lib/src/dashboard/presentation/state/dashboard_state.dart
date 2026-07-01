import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_summary.dart';

enum DashboardStatus { initial, loading, ready, error }

/// Immutable dashboard UI state.
class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.summary,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardSummary? summary;
  final String? errorMessage;

  const DashboardState.initial() : this();

  bool get isLoading => status == DashboardStatus.loading;
  bool get hasData => summary != null;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSummary? summary,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
