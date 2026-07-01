import '../../../core/domain/explainability.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/dashboard_summary.dart';


class DashboardDto {
  const DashboardDto(this.json);

  final Map<String, dynamic> json;

  factory DashboardDto.fromJson(Map<String, dynamic> json) => DashboardDto(json);

  Map<String, dynamic> toJson() => json;

  DashboardSummary toEntity() {
    final accounts = (json['accounts'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_accountFromJson)
        .toList(growable: false);

    final insight = json['insight'];
    return DashboardSummary(
      userId: (json['user_id'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      currency: (json['currency'] as String?) ?? 'INR',
      netWorth: _toDouble(json['net_worth']),
      totalAssets: _toDouble(json['total_assets']),
      totalLiabilities: _toDouble(json['total_liabilities']),
      monthlyChange: _toDouble(json['monthly_change']),
      accounts: accounts,
      insight: insight is Map<String, dynamic>
          ? Explanation.fromJson(insight)
          : const Explanation(summary: ''),
    );
  }

  static Account _accountFromJson(Map<String, dynamic> j) => Account(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        type: AccountType.fromWire((j['type'] as String?) ?? 'savings'),
        maskedNumber: (j['masked_number'] as String?) ?? '',
        balance: _toDouble(j['balance']),
        currency: (j['currency'] as String?) ?? 'INR',
        monthlyChange: _toDouble(j['monthly_change']),
      );

  static double _toDouble(Object? v) => (v as num?)?.toDouble() ?? 0.0;
}
