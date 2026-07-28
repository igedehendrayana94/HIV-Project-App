import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
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
      appBar: AppBar(title: const Text('Screening Questions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _AddQuestionScreen())),
        child: const Icon(Icons.add),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (questions) => ListView(
          children: questions
              .map((q) => ListTile(
                    title: Text(q.questionEn),
                    subtitle: Text('${q.domainKey} · ${q.key}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await dio.delete('/admin/screening-questions/${q.id}');
                        ref.invalidate(screeningQuestionsProvider);
                      },
                    ),
                  ))
              .toList(),
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
      appBar: AppBar(title: const Text('New Screening Question')),
      body: domainsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (domains) => Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _domainKey,
                  decoration: const InputDecoration(labelText: 'Domain'),
                  items: domains.map((d) => DropdownMenuItem(value: d.key, child: Text(d.label.text))).toList(),
                  onChanged: (v) => setState(() => _domainKey = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _key,
                  decoration: const InputDecoration(labelText: 'Key (unique, no spaces)'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Key is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _questionEn,
                  decoration: const InputDecoration(labelText: 'Question (English)'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _questionId,
                  decoration: const InputDecoration(labelText: 'Question (Bahasa Indonesia)'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Text('Severity 1-4 options', style: Theme.of(context).textTheme.titleSmall),
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text('${i + 1}. '),
                        Expanded(
                          child: TextFormField(
                            controller: _labelsEn[i],
                            decoration: const InputDecoration(labelText: 'Label (EN)'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _labelsId[i],
                            decoration: const InputDecoration(labelText: 'Label (ID)'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add Question'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
