import 'package:equatable/equatable.dart';

import '../../../core/domain/explainability.dart';
import 'account.dart';


class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.userId,
    required this.fullName,
    required this.currency,
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.monthlyChange,
    required this.accounts,
    required this.insight,
  });

  final String userId;
  final String fullName;
  final String currency;
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;

  final double monthlyChange;
  final List<Account> accounts;

  final Explanation insight;

  bool get isUp => monthlyChange >= 0;

  List<Account> get assets =>
      accounts.where((a) => !a.isLiability).toList(growable: false);
  List<Account> get liabilities =>
      accounts.where((a) => a.isLiability).toList(growable: false);

  @override
  List<Object?> get props => [
        userId,
        fullName,
        currency,
        netWorth,
        totalAssets,
        totalLiabilities,
        monthlyChange,
        accounts,
        insight,
      ];
}
