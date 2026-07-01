import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile.dart';

enum ProfileStatus { initial, loading, ready, error }

/// Immutable state for the profile/settings screen.
class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.saving = false,
    this.errorMessage,
  });

  final ProfileStatus status;
  final UserProfile? profile;

  /// True while a profile/preference update is in flight.
  final bool saving;
  final String? errorMessage;

  const ProfileState.initial() : this();

  bool get isLoading => status == ProfileStatus.loading;
  bool get hasData => profile != null;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, saving, errorMessage];
}
