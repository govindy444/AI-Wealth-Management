import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/profile_usecases.dart';
import 'profile_state.dart';

/// Drives the profile/settings screen: loads the profile and applies edits to
/// personal details, risk profile, and preferences.
class ProfileController extends StateNotifier<ProfileState> {
  ProfileController({
    required GetProfileUseCase getProfile,
    required UpdateProfileUseCase updateProfile,
    required UpdatePreferencesUseCase updatePreferences,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        _updatePreferences = updatePreferences,
        super(const ProfileState.initial());

  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final UpdatePreferencesUseCase _updatePreferences;

  Future<void> load() async {
    state = state.copyWith(status: ProfileStatus.loading, clearError: true);
    final result = await _getProfile(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      ),
      (profile) => state.copyWith(status: ProfileStatus.ready, profile: profile),
    );
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    RiskProfile? riskProfile,
  }) =>
      _apply(_updateProfile(UpdateProfileParams(
        fullName: fullName,
        phone: phone,
        riskProfile: riskProfile,
      )));

  Future<void> updatePreferences({
    bool? notificationsEnabled,
    bool? marketingEnabled,
    String? preferredLanguage,
    String? preferredCurrency,
    bool? dataConsent,
  }) =>
      _apply(_updatePreferences(UpdatePreferencesParams(
        notificationsEnabled: notificationsEnabled,
        marketingEnabled: marketingEnabled,
        preferredLanguage: preferredLanguage,
        preferredCurrency: preferredCurrency,
        dataConsent: dataConsent,
      )));

  Future<void> _apply(FutureResult<UserProfile> action) async {
    state = state.copyWith(saving: true, clearError: true);
    final result = await action;
    state = result.fold(
      (failure) => state.copyWith(saving: false, errorMessage: failure.message),
      (profile) => state.copyWith(
        saving: false,
        status: ProfileStatus.ready,
        profile: profile,
      ),
    );
  }
}
