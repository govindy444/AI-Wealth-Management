import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:demo_app/app/theme/theme_controller.dart';
import 'package:demo_app/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _profile({
  RiskProfile risk = RiskProfile.moderate,
  bool consent = true,
}) =>
    UserProfile(
      userId: 'usr_demo_0001',
      fullName: 'Demo User',
      email: 'demo@idbi.example',
      phone: '+91 90000 00000',
      kycStatus: KycStatus.verified,
      riskProfile: risk,
      memberSince: DateTime(2023, 4, 12),
      preferences: UserPreferences(
        notificationsEnabled: true,
        marketingEnabled: false,
        preferredLanguage: 'en',
        preferredCurrency: 'INR',
        dataConsent: consent,
      ),
    );

class _FakeProfileRepo implements ProfileRepository {
  bool? lastConsent;

  @override
  Future<Result<UserProfile>> getProfile() async => success(_profile());

  @override
  Future<Result<UserProfile>> updateProfile({
    String? fullName,
    String? phone,
    RiskProfile? riskProfile,
  }) async =>
      success(_profile(risk: riskProfile ?? RiskProfile.moderate));

  @override
  Future<Result<UserProfile>> updatePreferences({
    bool? notificationsEnabled,
    bool? marketingEnabled,
    String? preferredLanguage,
    String? preferredCurrency,
    bool? dataConsent,
  }) async {
    lastConsent = dataConsent;
    return success(_profile(consent: dataConsent ?? true));
  }
}

/// Auth controller stub that reports an authenticated session.
class _AuthedController extends AuthController {
  _AuthedController()
      : super(
          login: _NoopLogin(),
          register: _NoopRegister(),
          logout: _NoopLogout(),
          currentSession: _NoopSession(),
        ) {
    state = AuthState(
      status: AuthStatus.authenticated,
      session: AuthSession(
        accessToken: 't',
        refreshToken: 'r',
        expiresAt: DateTime(2030),
        user: const AuthUser(
          id: 'usr_demo_0001',
          email: 'demo@idbi.example',
          fullName: 'Demo User',
          roles: ['customer'],
        ),
      ),
    );
  }
}

class _NoopLogin extends LoginUseCase {
  _NoopLogin() : super(_DummyAuthRepo());
}

class _NoopRegister extends RegisterUseCase {
  _NoopRegister() : super(_DummyAuthRepo());
}

class _NoopLogout extends LogoutUseCase {
  _NoopLogout() : super(_DummyAuthRepo());
}

class _NoopSession extends GetCurrentSessionUseCase {
  _NoopSession() : super(_DummyAuthRepo());
}

class _DummyAuthRepo implements AuthRepository {
  @override
  Future<Result<AuthSession>> login({required String email, required String password}) async =>
      failure(const UnexpectedFailure('noop'));
  @override
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String fullName,
  }) async =>
      failure(const UnexpectedFailure('noop'));
  @override
  Future<Result<AuthSession>> refresh() async => failure(const UnexpectedFailure('noop'));
  @override
  Future<Result<void>> logout() async => success(null);
  @override
  Future<Result<AuthSession?>> currentSession() async => success(null);
}

Future<void> _pump(WidgetTester tester, _FakeProfileRepo repo) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.binding.setSurfaceSize(const Size(1000, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        authControllerProvider.overrideWith((ref) => _AuthedController()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows account, KYC and settings for a signed-in user',
      (tester) async {
    await _pump(tester, _FakeProfileRepo());

    expect(find.text('Demo User'), findsOneWidget);
    expect(find.textContaining('KYC Verified'), findsOneWidget);
    expect(find.text('Risk profile'), findsOneWidget);
    expect(find.text('AI data analysis'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('toggling AI data analysis updates the preference', (tester) async {
    final repo = _FakeProfileRepo();
    await _pump(tester, repo);

    // The data-consent switch starts on; tap to turn it off.
    final consentSwitch = find.widgetWithText(SwitchListTile, 'AI data analysis');
    await tester.tap(consentSwitch);
    await tester.pumpAndSettle();

    expect(repo.lastConsent, isFalse);
  });
}
