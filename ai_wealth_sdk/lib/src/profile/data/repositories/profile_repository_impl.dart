import '../../../core/data/base_repository.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Coordinates the profile API, mapping transport exceptions to [Failure]s via
/// [BaseRepository.guard]. Builds the request payloads from the optional fields.
class ProfileRepositoryImpl with BaseRepository implements ProfileRepository {
  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remote,
    required this.logger,
  }) : _remote = remote;

  final ProfileRemoteDataSource _remote;

  @override
  final SdkLogger logger;

  @override
  FutureResult<UserProfile> getProfile() => guard(() => _remote.getProfile());

  @override
  FutureResult<UserProfile> updateProfile({
    String? fullName,
    String? phone,
    RiskProfile? riskProfile,
  }) =>
      guard(() => _remote.updateProfile({
            if (fullName != null) 'full_name': fullName,
            if (phone != null) 'phone': phone,
            if (riskProfile != null) 'risk_profile': riskProfile.wire,
          }));

  @override
  FutureResult<UserProfile> updatePreferences({
    bool? notificationsEnabled,
    bool? marketingEnabled,
    String? preferredLanguage,
    String? preferredCurrency,
    bool? dataConsent,
  }) =>
      guard(() => _remote.updatePreferences({
            if (notificationsEnabled != null) 'notifications_enabled': notificationsEnabled,
            if (marketingEnabled != null) 'marketing_enabled': marketingEnabled,
            if (preferredLanguage != null) 'preferred_language': preferredLanguage,
            if (preferredCurrency != null) 'preferred_currency': preferredCurrency,
            if (dataConsent != null) 'data_consent': dataConsent,
          }));
}
