import '../../../core/network/api_client.dart';
import '../../domain/entities/user_profile.dart';
import '../models/profile_dtos.dart';

/// Talks to the backend `/profile` endpoints via the [ApiClient].
abstract interface class ProfileRemoteDataSource {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(Map<String, dynamic> body);
  Future<UserProfile> updatePreferences(Map<String, dynamic> body);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<UserProfile> getProfile() async {
    final res = await _client.get('/profile');
    return ProfileDtos.fromJson(res.asMap);
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> body) async {
    final res = await _client.patch('/profile', data: body);
    return ProfileDtos.fromJson(res.asMap);
  }

  @override
  Future<UserProfile> updatePreferences(Map<String, dynamic> body) async {
    final res = await _client.put('/profile/preferences', data: body);
    return ProfileDtos.fromJson(res.asMap);
  }
}
