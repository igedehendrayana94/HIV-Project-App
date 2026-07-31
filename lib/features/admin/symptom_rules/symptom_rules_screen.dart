import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/i18n.dart';

class SymptomRule {
  final int id;
  final String key;
  final String label;
  final bool highRisk;
  SymptomRule({required this.id, required this.key, required this.label, required this.highRisk});
  factory SymptomRule.fromJson(Map<String, dynamic> j) =>
      SymptomRule(id: j['id'] as int, key: j['key'] as String, label: j['label'] as String, highRisk: j['highRisk'] as bool);
}

final symptomRulesProvider = FutureProvider<List<SymptomRule>>((ref) async {
  final res = await dio.get('/admin/symptom-rules');
  return (res.data['rules'] as List).map((r) => SymptomRule.fromJson(r as Map<String, dynamic>)).toList();
});

class SymptomRulesScreen extends ConsumerWidget {
  const SymptomRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(symptomRulesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('symptomRules'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(symptomRulesProvider)),
        data: (rules) => RefreshIndicator(
          onRefresh: () => ref.refresh(symptomRulesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              for (final (i, r) in rules.indexed) ...[
                AppCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: Text(r.label),
                    value: r.highRisk,
                    onChanged: (v) async {
                      await dio.patch('/admin/symptom-rules/${r.id}', data: {'highRisk': v});
                      ref.invalidate(symptomRulesProvider);
                    },
                  ),
                ).animate(delay: (i * 40).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                if (i != rules.length - 1) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDialog(BuildContext context, WidgetRef ref) async {
    final key = TextEditingController();
    final label = TextEditingController();
    bool highRisk = true;
    String? error;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppStrings.t('newSymptomRule')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: key, decoration: InputDecoration(labelText: AppStrings.t('keyUniqueNoSpaces'))),
              TextField(controller: label, decoration: InputDecoration(labelText: AppStrings.t('label'))),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.t('highRisk')),
                value: highRisk,
                onChanged: (v) => setState(() => highRisk = v),
              ),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.t('cancel'))),
            FilledButton(
              onPressed: () async {
                try {
                  await dio.post('/admin/symptom-rules', data: {
                    'key': key.text.trim(),
                    'label': label.text.trim(),
                    'highRisk': highRisk,
                  });
                  ref.invalidate(symptomRulesProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() => error = apiErrorMessage(e));
                }
              },
              child: Text(AppStrings.t('add')),
            ),
          ],
        ),
      ),
    );
  }
}
