import 'package:equatable/equatable.dart';

import '../../domain/entities/fraud_reports.dart';

enum FraudStatus { initial, loading, ready, error }


class FraudState extends Equatable {
  const FraudState({
    this.status = FraudStatus.initial,
    this.report,
    this.messageCheck,
    this.checking = false,
    this.errorMessage,
  });

  final FraudStatus status;
  final FraudAlerts? report;

  final MessageCheck? messageCheck;
  final bool checking;
  final String? errorMessage;

  const FraudState.initial() : this();

  bool get isLoading => status == FraudStatus.loading;
  bool get hasData => report != null;

  FraudState copyWith({
    FraudStatus? status,
    FraudAlerts? report,
    MessageCheck? messageCheck,
    bool? checking,
    String? errorMessage,
    bool clearError = false,
    bool clearMessageCheck = false,
  }) {
    return FraudState(
      status: status ?? this.status,
      report: report ?? this.report,
      messageCheck:
          clearMessageCheck ? null : (messageCheck ?? this.messageCheck),
      checking: checking ?? this.checking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, report, messageCheck, checking, errorMessage];
}
