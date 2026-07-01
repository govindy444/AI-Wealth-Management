import 'package:equatable/equatable.dart';

enum PredictionType {
  salaryCredit,
  billDue,
  emiDue,
  lowBalance,
  taxReminder;

  static PredictionType fromWire(String value) => switch (value) {
        'salary_credit' => PredictionType.salaryCredit,
        'bill_due' => PredictionType.billDue,
        'emi_due' => PredictionType.emiDue,
        'low_balance' => PredictionType.lowBalance,
        'tax_reminder' => PredictionType.taxReminder,
        _ => PredictionType.billDue,
      };
}

enum PredictionSeverity {
  info,
  warning,
  critical;

  static PredictionSeverity fromWire(String value) => switch (value) {
        'critical' => PredictionSeverity.critical,
        'warning' => PredictionSeverity.warning,
        _ => PredictionSeverity.info,
      };
}

/// A single forward-looking prediction.
class Prediction extends Equatable {
  const Prediction({
    required this.type,
    required this.title,
    required this.message,
    required this.predictedDate,
    required this.daysAway,
    required this.severity,
    this.amount,
  });

  final PredictionType type;
  final String title;
  final String message;
  final DateTime predictedDate;
  final int daysAway;
  final PredictionSeverity severity;
  final double? amount;

  @override
  List<Object?> get props =>
      [type, title, message, predictedDate, daysAway, severity, amount];
}
