import '../../domain/entities/user_profile.dart';

/// Wire decoders for the profile endpoint.
class ProfileDtos {
  const ProfileDtos._();

  static UserProfile fromJson(Map<String, dynamic> j) => UserProfile(
        userId: (j['user_id'] as String?) ?? '',
        fullName: (j['full_name'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        phone: j['phone'] as String?,
        kycStatus: KycStatus.fromWire((j['kyc_status'] as String?) ?? 'not_started'),
        riskProfile: RiskProfile.fromWire((j['risk_profile'] as String?) ?? 'moderate'),
        memberSince:
            DateTime.tryParse(j['member_since'] as String? ?? '') ?? DateTime(2023, 1, 1),
        preferences: _prefsFromJson(
          (j['preferences'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );

  static UserPreferences _prefsFromJson(Map<String, dynamic> j) => UserPreferences(
        notificationsEnabled: (j['notifications_enabled'] as bool?) ?? true,
        marketingEnabled: (j['marketing_enabled'] as bool?) ?? false,
        preferredLanguage: (j['preferred_language'] as String?) ?? 'en',
        preferredCurrency: (j['preferred_currency'] as String?) ?? 'INR',
        dataConsent: (j['data_consent'] as bool?) ?? true,
      );
}
