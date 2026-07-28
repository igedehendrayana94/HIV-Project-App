import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'domains_provider.dart';
import 'models.dart';
import 'result_screen.dart';

class NewScreeningScreen extends ConsumerStatefulWidget {
  const NewScreeningScreen({super.key});

  @override
  ConsumerState<NewScreeningScreen> createState() => _NewScreeningScreenState();
}

class _NewScreeningScreenState extends ConsumerState<NewScreeningScreen> {
  // domainKey -> symptomKey -> answer — mirrors the Answers type POST /api/screening expects.
  final Map<String, Map<String, SymptomAnswer>> _answers = {};
  bool _submitting = false;
  String? _error;

  SymptomAnswer _answerFor(String domainKey, String symptomKey) {
    final domainAnswers = _answers.putIfAbsent(domainKey, () => {});
    return domainAnswers.putIfAbsent(symptomKey, () => SymptomAnswer());
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
      appBar: AppBar(title: const Text('New Screening')),
      body: domainsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (domains) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: domains.map((domain) => _DomainSection(
                      domain: domain,
                      answerFor: _answerFor,
                      onChanged: () => setState(() {}),
                    )).toList(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit Screening'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainSection extends StatelessWidget {
  final Domain domain;
  final SymptomAnswer Function(String domainKey, String symptomKey) answerFor;
  final VoidCallback onChanged;

  const _DomainSection({required this.domain, required this.answerFor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(domain.label.text, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: domain.symptoms.map((symptom) {
        final answer = answerFor(domain.key, symptom.key);
        return _SymptomTile(symptom: symptom, answer: answer, onChanged: onChanged);
      }).toList(),
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
            padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
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
