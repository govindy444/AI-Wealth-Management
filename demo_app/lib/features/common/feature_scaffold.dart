import 'package:flutter/material.dart';

import '../../app/responsive.dart';
import '../../app/theme/app_spacing.dart';


class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.moduleLabel,
    this.description,
  });

  final String title;
  final IconData icon;

  final String moduleLabel;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ResponsiveContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: scheme.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description ?? 'This experience is being crafted.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Chip(
                avatar: const Icon(Icons.construction, size: 18),
                label: Text(moduleLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
