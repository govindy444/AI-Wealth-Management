import 'package:equatable/equatable.dart';

enum HealthStatus {
  poor,
  fair,
  good,
  excellent;

  static HealthStatus fromWire(String value) => switch (value) {
        'excellent' => HealthStatus.excellent,
        'good' => HealthStatus.good,
        'fair' => HealthStatus.fair,
        _ => HealthStatus.poor,
      };
}


class HealthPillar extends Equatable {
  const HealthPillar({
    required this.key,
    required this.label,
    required this.score,
    required this.status,
    required this.detail,
    required this.recommendation,
  });

  final String key;
  final String label;
  final int score; // 0–100
  final HealthStatus status;
  final String detail;
  final String recommendation;

  @override
  List<Object?> get props => [key, label, score, status, detail, recommendation];
}
