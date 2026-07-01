import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';


class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(voiceControllerProvider.notifier).init(),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceControllerProvider);
    final notifier = ref.read(voiceControllerProvider.notifier);

    ref.listen(voiceControllerProvider, (prev, next) {
      if (next.status == VoiceStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final locales = state.config?.locales ?? const <VoiceLocale>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Assistant')),
      body: ResponsiveContainer(
        maxWidth: 560,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.lg),
            if (locales.isNotEmpty)
              _LocalePicker(
                locales: locales,
                selected: state.locale,
                onSelect: notifier.selectLocale,
              ),
            const SizedBox(height: AppSpacing.xl),
            _MicButton(state: state, notifier: notifier),
            const SizedBox(height: AppSpacing.lg),
            _StatusLine(state: state),
            const SizedBox(height: AppSpacing.lg),
            _Transcript(state: state),
            if (state.reply != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ReplyCard(
                reply: state.reply!,
                speaking: state.isSpeaking,
                onReplay: () => notifier.submitText(state.lastTranscript ?? ''),
                onStop: notifier.stopSpeaking,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _TypedFallback(
              controller: _input,
              enabled: !state.isBusy,
              hint: state.sttAvailable
                  ? 'Or type your question…'
                  : 'Voice input unavailable here — type your question:',
              onSend: () {
                final t = _input.text;
                _input.clear();
                notifier.submitText(t);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.state, required this.notifier});
  final VoiceState state;
  final VoiceController notifier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final listening = state.isListening;
    final processing = state.isProcessing;

    return Center(
      child: GestureDetector(
        onTap: () {
          if (listening) {
            notifier.cancelListening();
          } else if (!state.isBusy) {
            notifier.startListening();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: listening ? scheme.error : scheme.primary,
            boxShadow: [
              if (listening)
                BoxShadow(
                  color: scheme.error.withValues(alpha: 0.45),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
            ],
          ),
          child: processing
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Icon(
                  listening ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 56,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});
  final VoiceState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final label = switch (state.status) {
      VoiceStatus.listening => 'Listening…',
      VoiceStatus.processing => 'Thinking…',
      VoiceStatus.speaking => 'Speaking…',
      VoiceStatus.loadingConfig => 'Getting ready…',
      _ => state.sttAvailable
          ? 'Tap the mic and ask your question'
          : 'Tap to try voice, or type below',
    };
    return Center(
      child: Text(
        label,
        style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript({required this.state});
  final VoiceState state;

  @override
  Widget build(BuildContext context) {
    final shown = state.isListening
        ? (state.partialTranscript ?? '')
        : (state.lastTranscript ?? '');
    if (shown.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Center(
      child: Text(
        '“$shown”',
        textAlign: TextAlign.center,
        style: text.titleLarge?.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.reply,
    required this.speaking,
    required this.onReplay,
    required this.onStop,
  });
  final ChatMessage reply;
  final bool speaking;
  final VoidCallback onReplay;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Advisor', style: text.titleSmall),
                const Spacer(),
                if (speaking)
                  IconButton(
                    tooltip: 'Stop',
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_circle_outlined),
                  )
                else
                  IconButton(
                    tooltip: 'Replay',
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay_rounded),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(reply.content, style: text.bodyLarge),
            if (reply.hasExplanation) ...[
              const SizedBox(height: AppSpacing.sm),
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text('${reply.explanation!.confidencePercent}% confident'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocalePicker extends StatelessWidget {
  const _LocalePicker({
    required this.locales,
    required this.selected,
    required this.onSelect,
  });
  final List<VoiceLocale> locales;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        for (final l in locales)
          ChoiceChip(
            label: Text(l.label),
            selected: l.bcp47 == selected,
            onSelected: (_) => onSelect(l.bcp47),
          ),
      ],
    );
  }
}

class _TypedFallback extends StatelessWidget {
  const _TypedFallback({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          onPressed: enabled ? onSend : null,
          icon: const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}
