import 'package:equatable/equatable.dart';

import '../../domain/entities/forecast.dart';

enum PredictiveStatus { initial, loading, ready, error }

/// Immutable state for the predictive/forecast screen.
class PredictiveState extends Equatable {
  const PredictiveState({
    this.status = PredictiveStatus.initial,
    this.forecast,
    this.errorMessage,
  });

  final PredictiveStatus status;
  final Forecast? forecast;
  final String? errorMessage;

  const PredictiveState.initial() : this();

  bool get isLoading => status == PredictiveStatus.loading;
  bool get hasData => forecast != null;

  PredictiveState copyWith({
    PredictiveStatus? status,
    Forecast? forecast,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PredictiveState(
      status: status ?? this.status,
      forecast: forecast ?? this.forecast,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, forecast, errorMessage];
}
