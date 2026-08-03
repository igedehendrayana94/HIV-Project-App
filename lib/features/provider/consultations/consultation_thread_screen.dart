import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/i18n.dart';
import '../patient/patient_detail_screen.dart';
import 'models.dart';

// Polling, not push — same pattern as the web app's NotificationBell/ConsultationThread
// (no WebSocket/SSE infra in this project). 10s here since it's an active two-way chat, vs.
// the bell's 20s background badge check.
class ConsultationThreadScreen extends StatefulWidget {
  final int consultationId;
  // Claim/Mark Resolved and the patient-history shortcut are PROVIDER/ADMIN-only actions
  // (the backend already 403s a patient calling claim/resolve — this just keeps the
  // patient's own view of their thread from showing controls that aren't theirs to use).
  final bool isProviderView;
  const ConsultationThreadScreen({super.key, required this.consultationId, this.isProviderView = true});

  @override
  State<ConsultationThreadScreen> createState() => _ConsultationThreadScreenState();
}

class _ConsultationThreadScreenState extends State<ConsultationThreadScreen> {
  List<ConsultationThreadMessage> _messages = [];
  String _status = 'OPEN';
  int? _patientId;
  String? _patientName;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Timer? _timer;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await dio.get('/consultations/${widget.consultationId}/messages');
      if (!mounted) return;
      setState(() {
        _messages = (res.data['messages'] as List)
            .map((m) => ConsultationThreadMessage.fromJson(m as Map<String, dynamic>))
            .toList();
        _status = res.data['status'] as String;
        _patientId = res.data['patientId'] as int?;
        _patientName = res.data['patientName'] as String?;
        _error = null;
      });
    } catch (e) {
      if (!silent && mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    _input.clear();
    try {
      await dio.post('/consultations/${widget.consultationId}/messages', data: {'content': text});
      await _load(silent: true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    try {
      await dio.post('/consultations/${widget.consultationId}/claim');
      await _load();
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resolve() async {
    setState(() => _busy = true);
    try {
      await dio.patch('/consultations/${widget.consultationId}', data: {'status': 'RESOLVED'});
      await _load();
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isProviderView ? (_patientName ?? 'Consultation') : AppStrings.t('aiChatbot')),
        actions: [
          if (widget.isProviderView && _patientId != null)
            IconButton(
              icon: const Icon(Icons.folder_shared_outlined),
              tooltip: 'Patient history',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: _patientId!)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${AppStrings.t('status')}: $_status'),
                      if (widget.isProviderView && _status == 'OPEN')
                        FilledButton(onPressed: _busy ? null : _claim, child: Text(AppStrings.t('claim')))
                      else if (widget.isProviderView && _status == 'IN_REVIEW')
                        OutlinedButton(onPressed: _busy ? null : _resolve, child: Text(AppStrings.t('markResolved'))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      // "Is this my own message?" flips depending on who's viewing the thread —
                      // a provider's own messages go on the right when a provider is looking,
                      // but the same PROVIDER-authored message must go on the LEFT when the
                      // patient views the identical thread (their own PATIENT messages go right).
                      final isSelf = widget.isProviderView ? m.senderRole == 'PROVIDER' : m.senderRole == 'PATIENT';
                      return Align(
                        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isSelf
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.senderName != null)
                                Text(m.senderName!,
                                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                          color: isSelf ? Theme.of(context).colorScheme.onPrimary : null,
                                        )),
                              Text(m.content, style: TextStyle(color: isSelf ? Theme.of(context).colorScheme.onPrimary : null)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            enabled: _status != 'RESOLVED',
                            decoration: InputDecoration(hintText: AppStrings.t('typeMessage')),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          onPressed: _status == 'RESOLVED' || _busy ? null : _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
