import 'package:equatable/equatable.dart';

enum AccountType {
  savings,
  current,
  deposit,
  mutualFund,
  creditCard,
  loan;

  bool get isLiability =>
      this == AccountType.creditCard || this == AccountType.loan;

  /// Parses the backend's snake_case wire value.
  static AccountType fromWire(String value) => switch (value) {
        'savings' => AccountType.savings,
        'current' => AccountType.current,
        'deposit' => AccountType.deposit,
        'mutual_fund' => AccountType.mutualFund,
        'credit_card' => AccountType.creditCard,
        'loan' => AccountType.loan,
        _ => AccountType.savings,
      };
}

/// A single banking account shown on the dashboard.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.maskedNumber,
    required this.balance,
    required this.currency,
    required this.monthlyChange,
  });

  final String id;
  final String name;
  final AccountType type;

  final String maskedNumber;

  final double balance;
  final String currency;

  final double monthlyChange;

  bool get isLiability => type.isLiability;

  @override
  List<Object?> get props =>
      [id, name, type, maskedNumber, balance, currency, monthlyChange];
}
