import 'package:equatable/equatable.dart';

import '../../../recommendations/domain/entities/investment_product.dart'
    show RiskProfile;

export '../../../recommendations/domain/entities/investment_product.dart'
    show RiskProfile;

enum KycStatus {
  notStarted,
  pending,
  verified;

  static KycStatus fromWire(String value) => switch (value) {
        'verified' => KycStatus.verified,
        'pending' => KycStatus.pending,
        _ => KycStatus.notStarted,
      };

  String get label => switch (this) {
        KycStatus.verified => 'Verified',
        KycStatus.pending => 'Pending',
        KycStatus.notStarted => 'Not started',
      };
}

/// Editable user preferences.
class UserPreferences extends Equatable {
  const UserPreferences({
    required this.notificationsEnabled,
    required this.marketingEnabled,
    required this.preferredLanguage,
    required this.preferredCurrency,
    required this.dataConsent,
  });

  final bool notificationsEnabled;
  final bool marketingEnabled;
  final String preferredLanguage;
  final String preferredCurrency;

  /// Whether the customer consents to AI analysis of their financial data.
  final bool dataConsent;

  @override
  List<Object?> get props => [
        notificationsEnabled,
        marketingEnabled,
        preferredLanguage,
        preferredCurrency,
        dataConsent,
      ];
}

/// The user's profile and settings.
class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.kycStatus,
    required this.riskProfile,
    required this.memberSince,
    required this.preferences,
    this.phone,
  });

  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final KycStatus kycStatus;
  final RiskProfile riskProfile;
  final DateTime memberSince;
  final UserPreferences preferences;

  @override
  List<Object?> get props => [
        userId,
        fullName,
        email,
        phone,
        kycStatus,
        riskProfile,
        memberSince,
        preferences,
      ];
}
