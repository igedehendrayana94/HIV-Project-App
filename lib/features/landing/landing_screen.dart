import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/locale_state.dart';
import '../../core/theme.dart';
import '../../shared/ambient_glow.dart';
import '../../shared/i18n.dart';

// Mobile counterpart to HIV-Project-Web's public landing page (src/app/page.tsx) — same
// headline/value-prop copy, condensed to one scroll instead of the web page's multi-section
// scroll-reveal layout (no separate "how it works"/privacy sections here, this is a lighter
// pre-auth distillation, not a 1:1 port). Web's landing page already has an EN/ID toggle;
// this one didn't until now.
class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientGlow()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: SegmentedButton<AppLocale>(
                      segments: const [
                        ButtonSegment(value: AppLocale.id, label: Text('ID')),
                        ButtonSegment(value: AppLocale.en, label: Text('EN')),
                      ],
                      selected: {locale},
                      onSelectionChanged: (_) => ref.read(localeProvider.notifier).toggle(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Image.asset('assets/branding/logo.png', width: 88, height: 88),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppStrings.t('landingHeadline'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 32),
                  ).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.t('landingSubtext'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate(delay: 140.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: kVibrantPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: kVibrantPrimary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: kVibrantPrimary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(AppStrings.t('landingU2UInfo'), style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  for (final (i, item) in [
                    (Icons.checklist_rtl, AppStrings.t('landingValueScreening')),
                    (Icons.chat_bubble_outline, AppStrings.t('landingValueAssistant')),
                    (Icons.lock_outline, AppStrings.t('landingValuePrivate')),
                  ].indexed) ...[
                    Row(
                      children: [
                        Icon(item.$1, color: kVibrantPrimary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(item.$2, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ).animate(delay: (260 + i * 60).ms).fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: Text(AppStrings.t('landingSignIn')),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => context.go('/signup'),
                    child: Text(AppStrings.t('landingCreateAccount')),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppStrings.t('landingFooterTagline'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
