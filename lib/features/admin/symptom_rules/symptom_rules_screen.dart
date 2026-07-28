import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

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
      appBar: AppBar(title: const Text('Symptom Rules')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (rules) => ListView(
          children: rules
              .map((r) => SwitchListTile(
                    title: Text(r.label),
                    subtitle: Text(r.key),
                    value: r.highRisk,
                    onChanged: (v) async {
                      await dio.patch('/admin/symptom-rules/${r.id}', data: {'highRisk': v});
                      ref.invalidate(symptomRulesProvider);
                    },
                  ))
              .toList(),
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
          title: const Text('New Symptom Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: key, decoration: const InputDecoration(labelText: 'Key (unique, no spaces)')),
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High Risk'),
                value: highRisk,
                onChanged: (v) => setState(() => highRisk = v),
              ),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
