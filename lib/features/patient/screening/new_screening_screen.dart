import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/i18n.dart';
import '../history/history_provider.dart';
import 'domains_provider.dart';
import 'models.dart';
import 'result_screen.dart';

// One domain per step (PageView + Next/Back), not one long scrollable list of 6 accordions —
// the original ExpansionTile-per-domain layout let a patient reach the submit button without
// ever opening several domains, and made the form read as a wall of collapsed sections up
// front. A guided step-by-step flow matches this app's "calm health app" reference class
// (Headspace/Calm-style onboarding pacing) better than a dense settings-style list.
// Scoring/submission logic (_answers, _answerFor, _submit) is completely unchanged from the
// previous version — only the navigation shell around it changed.
//
// Self-screening only — the app used to also let a Provider run this on behalf of any patient
// (via a patient-picker screen, optional patientId/patientName params here), removed per
// explicit request. Provider still sees a patient's screening history read-only.
class NewScreeningScreen extends ConsumerStatefulWidget {
  const NewScreeningScreen({super.key});

  @override
  ConsumerState<NewScreeningScreen> createState() => _NewScreeningScreenState();
}

class _NewScreeningScreenState extends ConsumerState<NewScreeningScreen> {
  final Map<String, Map<String, SymptomAnswer>> _answers = {};
  final _pageController = PageController();
  int _page = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  SymptomAnswer _answerFor(String domainKey, String symptomKey) {
    final domainAnswers = _answers.putIfAbsent(domainKey, () => {});
    return domainAnswers.putIfAbsent(symptomKey, () => SymptomAnswer());
  }

  void _goNext(int domainCount) {
    if (_page < domainCount - 1) {
      setState(() => _page++);
      _pageController.nextPage(duration: 250.ms, curve: Curves.easeOut);
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_page == 0) return;
    setState(() => _page--);
    _pageController.previousPage(duration: 250.ms, curve: Curves.easeOut);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final answersJson = {
      for (final domainEntry in _answers.entries)
        domainEntry.key: {
          for (final symptomEntry in domainEntry.value.entries)
            if (symptomEntry.value.stage1) symptomEntry.key: symptomEntry.value.toJson(),
        },
    };
    try {
      final res = await dio.post('/screening', data: {'answers': answersJson});
      ref.invalidate(screeningHistoryProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScreeningResultScreen(
            overallRisk: res.data['overallRisk'] as String,
            redFlag: res.data['redFlag'] as bool,
            domainScores: res.data['domainScores'] as Map<String, dynamic>,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainsAsync = ref.watch(domainsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('newScreening'))),
      body: domainsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(domainsProvider)),
        data: (domains) {
          final domain = domains[_page];
          final isLast = _page == domains.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_page + 1) / domains.length,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      domain.label.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: domains.length,
                  itemBuilder: (context, i) {
                    final d = domains[i];
                    return ListView(
                      key: ValueKey(d.key),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: d.symptoms.map((symptom) {
                              final answer = _answerFor(d.key, symptom.key);
                              return _SymptomTile(
                                symptom: symptom,
                                answer: answer,
                                onChanged: () => setState(() {}),
                              );
                            }).toList(),
                          ),
                        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0),
                      ],
                    );
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    if (_page > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : _goBack,
                          child: Text(AppStrings.t('back')),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : () => _goNext(domains.length),
                        child: _submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(isLast ? AppStrings.t('submitScreening') : AppStrings.t('next')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SymptomTile extends StatefulWidget {
  final Symptom symptom;
  final SymptomAnswer answer;
  final VoidCallback onChanged;

  const _SymptomTile({required this.symptom, required this.answer, required this.onChanged});

  @override
  State<_SymptomTile> createState() => _SymptomTileState();
}

class _SymptomTileState extends State<_SymptomTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(widget.symptom.question.text),
          value: widget.answer.stage1,
          onChanged: (v) {
            setState(() {
              widget.answer.stage1 = v;
              if (!v) widget.answer.stage2 = null;
            });
            widget.onChanged();
          },
        ),
        if (widget.answer.stage1)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.md, bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.symptom.stage2Options.map((opt) {
                return RadioListTile<int>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt.label.text),
                  value: opt.score,
                  groupValue: widget.answer.stage2,
                  onChanged: (v) {
                    setState(() => widget.answer.stage2 = v);
                    widget.onChanged();
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
