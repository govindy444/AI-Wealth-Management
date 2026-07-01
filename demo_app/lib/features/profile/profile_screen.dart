import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router/app_routes.dart';
import '../../app/theme/app_spacing.dart';
import 'theme_mode_selector.dart';

const _languageNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'mr': 'मराठी',
  'ta': 'தமிழ்',
  'bn': 'বাংলা',
};


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authControllerProvider).isAuthenticated) {
        ref.read(profileControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    final name = profile?.fullName ?? auth.session?.user.fullName ?? 'Guest';
    final email = profile?.email ?? auth.session?.user.email ?? 'Not signed in';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsiveContainer(
        child: ListView(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.person, size: 36, color: scheme.primary),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: text.titleLarge),
                      Text(email,
                          style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (profile != null)
                  Chip(
                    avatar: Icon(
                      profile.kycStatus == KycStatus.verified
                          ? Icons.verified
                          : Icons.pending_outlined,
                      size: 18,
                    ),
                    label: Text('KYC ${profile.kycStatus.label}'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            if (profile != null) ...[
              _AccountCard(profile: profile),
              const SizedBox(height: AppSpacing.lg),
              _SettingsCard(profile: profile, saving: profileState.saving),
              const SizedBox(height: AppSpacing.lg),
            ],

            Text('Appearance', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            const ThemeModeSelector(),
            const SizedBox(height: AppSpacing.xl),

            if (auth.isAuthenticated)
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              )
            else
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.login),
                icon: const Icon(Icons.login),
                label: const Text('Sign in'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(profileControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _row(context, 'Phone', profile.phone ?? '—'),
            _row(context, 'Member since',
                '${profile.memberSince.year}'),
            const SizedBox(height: AppSpacing.sm),
            Text('Risk profile', style: text.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final p in RiskProfile.values)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: p == profile.riskProfile,
                    onSelected: (_) => notifier.updateProfile(riskProfile: p),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text(label,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.profile, required this.saving});
  final UserProfile profile;
  final bool saving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final prefs = profile.preferences;
    final notifier = ref.read(profileControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Text('Settings', style: text.titleSmall),
            ),
            SwitchListTile(
              title: const Text('Push notifications'),
              value: prefs.notificationsEnabled,
              onChanged: saving
                  ? null
                  : (v) => notifier.updatePreferences(notificationsEnabled: v),
            ),
            SwitchListTile(
              title: const Text('Marketing emails'),
              value: prefs.marketingEnabled,
              onChanged: saving
                  ? null
                  : (v) => notifier.updatePreferences(marketingEnabled: v),
            ),
            SwitchListTile(
              title: const Text('AI data analysis'),
              subtitle: const Text(
                  'Let your AI advisor analyse your accounts for insights.'),
              value: prefs.dataConsent,
              onChanged: saving
                  ? null
                  : (v) => notifier.updatePreferences(dataConsent: v),
            ),
            ListTile(
              title: const Text('Language'),
              trailing: DropdownButton<String>(
                value: _languageNames.containsKey(prefs.preferredLanguage)
                    ? prefs.preferredLanguage
                    : 'en',
                underline: const SizedBox.shrink(),
                onChanged: saving
                    ? null
                    : (code) {
                        if (code != null) {
                          notifier.updatePreferences(preferredLanguage: code);
                        }
                      },
                items: [
                  for (final e in _languageNames.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
