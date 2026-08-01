import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/confirm_dialog.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/i18n.dart';
import '../../patient/screening/domains_provider.dart';

class ScreeningQuestion {
  final int id;
  final String domainKey;
  final String key;
  final String questionEn;
  ScreeningQuestion({required this.id, required this.domainKey, required this.key, required this.questionEn});
  factory ScreeningQuestion.fromJson(Map<String, dynamic> j) => ScreeningQuestion(
        id: j['id'] as int,
        domainKey: j['domainKey'] as String,
        key: j['key'] as String,
        questionEn: j['questionEn'] as String,
      );
}

final screeningQuestionsProvider = FutureProvider<List<ScreeningQuestion>>((ref) async {
  final res = await dio.get('/admin/screening-questions');
  return (res.data['questions'] as List).map((q) => ScreeningQuestion.fromJson(q as Map<String, dynamic>)).toList();
});

class ScreeningQuestionsScreen extends ConsumerWidget {
  const ScreeningQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(screeningQuestionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('screeningQuestions'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _AddQuestionScreen())),
        child: const Icon(Icons.add),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(screeningQuestionsProvider)),
        data: (questions) => RefreshIndicator(
          onRefresh: () => ref.refresh(screeningQuestionsProvider.future),
          child: questions.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    // No key covers this empty state yet — left as plain English.
                    const EmptyState(icon: Icons.fact_check_outlined, message: 'No screening questions yet.'),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    for (final (i, q) in questions.indexed) ...[
                      AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.questionEn, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${q.domainKey} · ${q.key}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await confirmAction(
                                  context,
                                  title: AppStrings.t('areYouSure'),
                                  message: AppStrings.t('deleteQuestionConfirmMessage'),
                                  confirmLabel: AppStrings.t('delete'),
                                  destructive: true,
                                );
                                if (!ok) return;
                                await dio.delete('/admin/screening-questions/${q.id}');
                                ref.invalidate(screeningQuestionsProvider);
                              },
                            ),
                          ],
                        ),
                      ).animate(delay: (i * 40).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                      if (i != questions.length - 1) const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

// stage2Options is a 1-4 severity scale for every built-in symptom except one special case
// (seizures, 3-4 only) — this form always creates the standard 4-point scale rather than a
// fully dynamic add/remove list editor. Delete + recreate for anything unusual.
class _AddQuestionScreen extends ConsumerStatefulWidget {
  const _AddQuestionScreen();

  @override
  ConsumerState<_AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends ConsumerState<_AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _domainKey;
  final _key = TextEditingController();
  final _questionEn = TextEditingController();
  final _questionId = TextEditingController();
  final _labelsEn = List.generate(4, (_) => TextEditingController());
  final _labelsId = List.generate(4, (_) => TextEditingController());
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _domainKey == null) {
      // No i18n key exists for this validation message — left as plain English.
      setState(() => _error = _domainKey == null ? 'Domain is required' : null);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await dio.post('/admin/screening-questions', data: {
        'domainKey': _domainKey,
        'key': _key.text.trim(),
        'questionEn': _questionEn.text.trim(),
        'questionId': _questionId.text.trim(),
        'stage2Options': [
          for (var i = 0; i < 4; i++)
            {'labelEn': _labelsEn[i].text.trim(), 'labelId': _labelsId[i].text.trim(), 'score': i + 1},
        ],
      });
      ref.invalidate(screeningQuestionsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainsAsync = ref.watch(domainsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('newScreeningQuestion'))),
      body: domainsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(domainsProvider)),
        data: (domains) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _domainKey,
                  decoration: InputDecoration(labelText: AppStrings.t('domain')),
                  items: domains.map((d) => DropdownMenuItem(value: d.key, child: Text(d.label.text))).toList(),
                  onChanged: (v) => setState(() => _domainKey = v),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _key,
                  decoration: InputDecoration(labelText: AppStrings.t('keyUniqueNoSpaces')),
                  validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('keyRequired') : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _questionEn,
                  decoration: InputDecoration(labelText: AppStrings.t('questionEnglish')),
                  validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('required') : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _questionId,
                  decoration: InputDecoration(labelText: AppStrings.t('questionIndonesian')),
                  validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('required') : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(AppStrings.t('severityOptions1to4'), style: Theme.of(context).textTheme.titleSmall),
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        Text('${i + 1}. '),
                        Expanded(
                          child: TextFormField(
                            controller: _labelsEn[i],
                            decoration: InputDecoration(labelText: AppStrings.t('labelEn')),
                            validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('required') : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _labelsId[i],
                            decoration: InputDecoration(labelText: AppStrings.t('labelId')),
                            validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('required') : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppStrings.t('addQuestion')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
