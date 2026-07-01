import 'package:equatable/equatable.dart';

import '../../domain/entities/portfolio_summary.dart';

enum PortfolioStatus { initial, loading, ready, error }

/// Immutable state for the portfolio screen.
class PortfolioState extends Equatable {
  const PortfolioState({
    this.status = PortfolioStatus.initial,
    this.summary,
    this.errorMessage,
  });

  final PortfolioStatus status;
  final PortfolioSummary? summary;
  final String? errorMessage;

  const PortfolioState.initial() : this();

  bool get isLoading => status == PortfolioStatus.loading;
  bool get hasData => summary != null;

  PortfolioState copyWith({
    PortfolioStatus? status,
    PortfolioSummary? summary,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PortfolioState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
