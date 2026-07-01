import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/profile/data/datasources/profile_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/profile/data/models/profile_dtos.dart';
import 'package:ai_wealth_sdk/src/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _json({
  String risk = 'moderate',
  bool consent = true,
  String lang = 'en',
}) =>
    {
      'user_id': 'usr_demo_0001',
      'full_name': 'Demo User',
      'email': 'demo@idbi.example',
      'phone': '+91 90000 00000',
      'kyc_status': 'verified',
      'risk_profile': risk,
      'member_since': '2023-04-12',
      'preferences': {
        'notifications_enabled': true,
        'marketing_enabled': false,
        'preferred_language': lang,
        'preferred_currency': 'INR',
        'data_consent': consent,
      },
    };

void main() {
  group('ProfileDtos', () {
    test('decodes profile with kyc, risk and preferences', () {
      final p = ProfileDtos.fromJson(_json());
      expect(p.fullName, 'Demo User');
      expect(p.kycStatus, KycStatus.verified);
      expect(p.riskProfile, RiskProfile.moderate);
      expect(p.preferences.dataConsent, isTrue);
      expect(p.preferences.preferredCurrency, 'INR');
      expect(p.memberSince.year, 2023);
    });
  });

  group('ProfileController', () {
    ProfileController controller(FakeRemote remote) {
      final repo = ProfileRepositoryImpl(remote: remote, logger: _logger);
      return ProfileController(
        getProfile: GetProfileUseCase(repo),
        updateProfile: UpdateProfileUseCase(repo),
        updatePreferences: UpdatePreferencesUseCase(repo),
      );
    }

    test('load populates the profile', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, ProfileStatus.ready);
      expect(c.state.profile?.email, 'demo@idbi.example');
    });

    test('updateProfile sends the risk profile and refreshes', () async {
      final remote = FakeRemote();
      final c = controller(remote);
      addTearDown(c.dispose);
      await c.load();

      await c.updateProfile(riskProfile: RiskProfile.aggressive);

      expect(remote.lastProfileBody?['risk_profile'], 'aggressive');
      expect(c.state.profile?.riskProfile, RiskProfile.aggressive);
      expect(c.state.saving, isFalse);
    });

    test('updatePreferences toggles data consent', () async {
      final remote = FakeRemote();
      final c = controller(remote);
      addTearDown(c.dispose);
      await c.load();

      await c.updatePreferences(dataConsent: false);

      expect(remote.lastPrefsBody?['data_consent'], false);
      expect(c.state.profile?.preferences.dataConsent, isFalse);
    });

    test('surfaces an error on load failure', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.load();
      expect(c.state.status, ProfileStatus.error);
    });
  });
}

class FakeRemote implements ProfileRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  Map<String, dynamic>? lastProfileBody;
  Map<String, dynamic>? lastPrefsBody;

  @override
  Future<UserProfile> getProfile() async {
    if (_fail) throw NetworkException('offline');
    return ProfileDtos.fromJson(_json());
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> body) async {
    lastProfileBody = body;
    return ProfileDtos.fromJson(_json(risk: body['risk_profile'] as String? ?? 'moderate'));
  }

  @override
  Future<UserProfile> updatePreferences(Map<String, dynamic> body) async {
    lastPrefsBody = body;
    return ProfileDtos.fromJson(_json(consent: body['data_consent'] as bool? ?? true));
  }
}
