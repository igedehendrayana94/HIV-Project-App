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

class StageOption {
  final String labelEn;
  final String labelId;
  final int score;
  StageOption({required this.labelEn, required this.labelId, required this.score});
  factory StageOption.fromJson(Map<String, dynamic> j) => StageOption(
        labelEn: j['labelEn'] as String,
        labelId: j['labelId'] as String,
        score: j['score'] as int,
      );
}

class ScreeningQuestion {
  final int id;
  final String domainKey;
  final String key;
  final String questionEn;
  final String questionId;
  final List<StageOption> stage2Options;
  final int? redFlagAtScore;
  ScreeningQuestion({
    required this.id,
    required this.domainKey,
    required this.key,
    required this.questionEn,
    required this.questionId,
    required this.stage2Options,
    required this.redFlagAtScore,
  });
  factory ScreeningQuestion.fromJson(Map<String, dynamic> j) => ScreeningQuestion(
        id: j['id'] as int,
        domainKey: j['domainKey'] as String,
        key: j['key'] as String,
        questionEn: j['questionEn'] as String,
        questionId: j['questionId'] as String,
        stage2Options: (j['stage2Options'] as List)
            .map((o) => StageOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        redFlagAtScore: j['redFlagAtScore'] as int?,
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
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _QuestionFormScreen())),
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
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => _QuestionFormScreen(existing: q))),
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

// stage2Options is normally a 1-4 severity scale, but at least one built-in symptom
// ("seizures/decreased consciousness") only has 2 options (scores 3-4) — the option list below
// is a dynamic add/remove list rather than a hardcoded 4-slot form, so that case (and any
// future non-standard one) can be created/edited without fabricating fake labels.
class _OptionRow {
  final TextEditingController score;
  final TextEditingController labelEn;
  final TextEditingController labelId;
  _OptionRow({String score = '', String labelEn = '', String labelId = ''})
      : score = TextEditingController(text: score),
        labelEn = TextEditingController(text: labelEn),
        labelId = TextEditingController(text: labelId);
}

class _QuestionFormScreen extends ConsumerStatefulWidget {
  final ScreeningQuestion? existing;
  const _QuestionFormScreen({this.existing});

  @override
  ConsumerState<_QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends ConsumerState<_QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _domainKey;
  late final _key = TextEditingController(text: widget.existing?.key ?? '');
  late final _questionEn = TextEditingController(text: widget.existing?.questionEn ?? '');
  late final _questionId = TextEditingController(text: widget.existing?.questionId ?? '');
  late final List<_OptionRow> _options = widget.existing != null
      ? widget.existing!.stage2Options
          .map((o) => _OptionRow(score: '${o.score}', labelEn: o.labelEn, labelId: o.labelId))
          .toList()
      : List.generate(4, (i) => _OptionRow(score: '${i + 1}'));
  late bool _redFlag = widget.existing?.redFlagAtScore != null;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _domainKey = widget.existing?.domainKey;
  }

  int _maxOptionScore() =>
      _options.map((o) => int.tryParse(o.score.text) ?? 0).fold(0, (a, b) => a > b ? a : b);

  void _addOption() {
    setState(() => _options.add(_OptionRow(score: '${_maxOptionScore() + 1}')));
  }

  void _removeOption(int i) {
    if (_options.length <= 1) return;
    setState(() => _options.removeAt(i));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _domainKey == null) {
      setState(() => _error = _domainKey == null ? AppStrings.t('domainRequired') : null);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = {
      'domainKey': _domainKey,
      'key': _key.text.trim(),
      'questionEn': _questionEn.text.trim(),
      'questionId': _questionId.text.trim(),
      'stage2Options': [
        for (final o in _options)
          {
            'labelEn': o.labelEn.text.trim(),
            'labelId': o.labelId.text.trim(),
            'score': int.tryParse(o.score.text) ?? 0,
          },
      ],
      'redFlagAtScore': _redFlag ? _maxOptionScore() : null,
    };
    try {
      final existing = widget.existing;
      if (existing == null) {
        await dio.post('/admin/screening-questions', data: data);
      } else {
        await dio.patch('/admin/screening-questions/${existing.id}', data: data);
      }
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
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.t('edit') : AppStrings.t('newScreeningQuestion')),
      ),
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
                Text(AppStrings.t('severityOptionsVariable'), style: Theme.of(context).textTheme.titleSmall),
                for (var i = 0; i < _options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: TextFormField(
                            controller: _options[i].score,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: AppStrings.t('score')),
                            validator: (v) => (v == null || int.tryParse(v) == null) ? '' : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _options[i].labelEn,
                            decoration: InputDecoration(labelText: AppStrings.t('labelEn')),
                            validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('required') : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _options[i].labelId,
                            decoration: InputDecoration(labelText: AppStrings.t('labelId')),
                            validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('required') : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _options.length <= 1 ? null : () => _removeOption(i),
                        ),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: _addOption,
                  child: Text(AppStrings.t('addOption')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.t('redFlagAtMaxScore')),
                  value: _redFlag,
                  onChanged: (v) => setState(() => _redFlag = v),
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
                      : Text(isEditing ? AppStrings.t('save') : AppStrings.t('addQuestion')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
