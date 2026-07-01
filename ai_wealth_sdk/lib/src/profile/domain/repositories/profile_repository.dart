import '../../../core/utils/result.dart';
import '../entities/user_profile.dart';

/// Profile & Settings repository contract.
abstract interface class ProfileRepository {
  FutureResult<UserProfile> getProfile();

  FutureResult<UserProfile> updateProfile({
    String? fullName,
    String? phone,
    RiskProfile? riskProfile,
  });

  FutureResult<UserProfile> updatePreferences({
    bool? notificationsEnabled,
    bool? marketingEnabled,
    String? preferredLanguage,
    String? preferredCurrency,
    bool? dataConsent,
  });
}
