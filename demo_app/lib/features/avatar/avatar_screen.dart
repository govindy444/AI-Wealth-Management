import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';
import 'avatar_face.dart';

/// Human-readable labels for the language codes the avatar supports.
const _languageNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'mr': 'मराठी',
  'ta': 'தமிழ்',
  'bn': 'বাংলা',
};

Color _parseHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0x6C4DF4;
  return Color(0xFF000000 | value);
}


class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(avatarControllerProvider.notifier).init(),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(avatarControllerProvider);
    final notifier = ref.read(avatarControllerProvider.notifier);
    final persona = state.selectedPersona;

    ref.listen(avatarControllerProvider, (prev, next) {
      if (next.status == AvatarStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final accent = persona != null
        ? _parseHex(persona.accentColorHex)
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Avatar')),
      body: state.personas.isEmpty && state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveContainer(
              maxWidth: 560,
              child: ListView(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _Stage(state: state, accent: accent),
                  const SizedBox(height: AppSpacing.lg),
                  if (persona != null) ...[
                    _PersonaPicker(
                      personas: state.personas,
                      selectedId: persona.id,
                      onSelect: notifier.selectPersona,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _LanguagePicker(
                      languages: persona.languages,
                      selected: state.language,
                      onSelect: notifier.selectLanguage,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _Composer(
                    controller: _input,
                    busy: state.isLoading,
                    speaking: state.speaking,
                    onSpeak: () {
                      final t = _input.text.trim();
                      notifier.speak(text: t.isEmpty ? null : t);
                    },
                    onGreet: () => notifier.speak(),
                    onStop: notifier.stop,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.state, required this.accent});
  final AvatarState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final persona = state.selectedPersona;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (state.speaking)
                BoxShadow(
                  color: accent.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
            ],
          ),
          child: AvatarFace(
            expression: state.expression,
            speaking: state.speaking,
            accent: accent,
            size: 188,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (persona != null) ...[
          Text(persona.name, style: text.titleLarge),
          Text(
            persona.title,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            state.currentCaption ??
                (state.presentation?.text ??
                    'Pick a language and tap "Greet me", or type a message for your avatar to deliver.'),
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PersonaPicker extends StatelessWidget {
  const _PersonaPicker({
    required this.personas,
    required this.selectedId,
    required this.onSelect,
  });
  final List<AvatarPersona> personas;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final p in personas)
          ChoiceChip(
            avatar: CircleAvatar(
              backgroundColor: _parseHex(p.accentColorHex),
              radius: 10,
            ),
            label: Text(p.name),
            selected: p.id == selectedId,
            onSelected: (_) => onSelect(p.id),
          ),
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.languages,
    required this.selected,
    required this.onSelect,
  });
  final List<String> languages;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final code in languages)
          ChoiceChip(
            label: Text(_languageNames[code] ?? code),
            selected: code == selected,
            onSelected: (_) => onSelect(code),
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.speaking,
    required this.onSpeak,
    required this.onGreet,
    required this.onStop,
  });

  final TextEditingController controller;
  final bool busy;
  final bool speaking;
  final VoidCallback onSpeak;
  final VoidCallback onGreet;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Type what the avatar should say…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : onSpeak,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Speak'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: busy ? null : onGreet,
              icon: const Icon(Icons.waving_hand_outlined),
              label: const Text('Greet me'),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'Stop',
              onPressed: speaking ? onStop : null,
              icon: const Icon(Icons.stop_circle_outlined),
            ),
          ],
        ),
      ],
    );
  }
}
