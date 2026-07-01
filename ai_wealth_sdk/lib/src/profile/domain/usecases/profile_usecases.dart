import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase implements UseCase<UserProfile, NoParams> {
  GetProfileUseCase(this._repository);
  final ProfileRepository _repository;

  @override
  FutureResult<UserProfile> call(NoParams params) => _repository.getProfile();
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({this.fullName, this.phone, this.riskProfile});
  final String? fullName;
  final String? phone;
  final RiskProfile? riskProfile;

  @override
  List<Object?> get props => [fullName, phone, riskProfile];
}

class UpdateProfileUseCase implements UseCase<UserProfile, UpdateProfileParams> {
  UpdateProfileUseCase(this._repository);
  final ProfileRepository _repository;

  @override
  FutureResult<UserProfile> call(UpdateProfileParams p) => _repository.updateProfile(
        fullName: p.fullName,
        phone: p.phone,
        riskProfile: p.riskProfile,
      );
}

class UpdatePreferencesParams extends Equatable {
  const UpdatePreferencesParams({
    this.notificationsEnabled,
    this.marketingEnabled,
    this.preferredLanguage,
    this.preferredCurrency,
    this.dataConsent,
  });
  final bool? notificationsEnabled;
  final bool? marketingEnabled;
  final String? preferredLanguage;
  final String? preferredCurrency;
  final bool? dataConsent;

  @override
  List<Object?> get props => [
        notificationsEnabled,
        marketingEnabled,
        preferredLanguage,
        preferredCurrency,
        dataConsent,
      ];
}

class UpdatePreferencesUseCase
    implements UseCase<UserProfile, UpdatePreferencesParams> {
  UpdatePreferencesUseCase(this._repository);
  final ProfileRepository _repository;

  @override
  FutureResult<UserProfile> call(UpdatePreferencesParams p) =>
      _repository.updatePreferences(
        notificationsEnabled: p.notificationsEnabled,
        marketingEnabled: p.marketingEnabled,
        preferredLanguage: p.preferredLanguage,
        preferredCurrency: p.preferredCurrency,
        dataConsent: p.dataConsent,
      );
}
