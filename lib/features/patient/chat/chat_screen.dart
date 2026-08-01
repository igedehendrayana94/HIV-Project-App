import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/i18n.dart';

class ChatMessage {
  final String role; // "USER" | "ASSISTANT"
  final String content;
  ChatMessage({required this.role, required this.content});
  factory ChatMessage.fromJson(Map<String, dynamic> j) =>
      ChatMessage(role: j['role'] as String, content: j['content'] as String);
}

class PendingEscalation {
  final String reason;
  final String urgency;
  PendingEscalation({required this.reason, required this.urgency});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int? _chatSessionId;
  final List<ChatMessage> _messages = [];
  final _input = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  bool _escalated = false;
  int? _consultationId;
  PendingEscalation? _pending;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final res = await dio.post('/chat/start');
      final session = res.data['chatSession'] as Map<String, dynamic>;
      setState(() {
        _chatSessionId = session['id'] as int;
        _escalated = session['status'] != 'OPEN';
        _messages
          ..clear()
          ..addAll((session['messages'] as List).map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)));
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _chatSessionId == null) return;
    setState(() {
      _messages.add(ChatMessage(role: 'USER', content: text));
      _sending = true;
      _error = null;
    });
    _input.clear();
    try {
      final res = await dio.post('/chat/$_chatSessionId/messages', data: {'content': text});
      final assistant = (res.data['messages'] as List).last as Map<String, dynamic>;
      setState(() {
        _messages.add(ChatMessage.fromJson(assistant));
        _escalated = res.data['escalated'] as bool;
        _consultationId = res.data['consultationId'] as int?;
        final pe = res.data['pendingEscalation'];
        _pending = pe == null ? null : PendingEscalation(reason: pe['reason'] as String, urgency: pe['urgency'] as String);
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmEscalation() async {
    if (_chatSessionId == null || _pending == null) return;
    setState(() => _sending = true);
    try {
      final res = await dio.post('/chat/$_chatSessionId/escalate', data: {
        'reason': _pending!.reason,
        'urgency': _pending!.urgency,
      });
      setState(() {
        _escalated = true;
        _consultationId = res.data['consultationId'] as int?;
        _pending = null;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('aiChatbot'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_escalated)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: AppCard(
                      child: Text(
                        _consultationId != null
                            ? AppStrings.escalatedToConsultation(_consultationId!)
                            : AppStrings.t('chatEnded'),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isUser = m.role == 'USER';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.content,
                            style: TextStyle(color: isUser ? Theme.of(context).colorScheme.onPrimary : null),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_pending != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.assistantSuggestsProvider(_pending!.urgency)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilledButton(
                                  onPressed: _sending ? null : _confirmEscalation,
                                  child: Text(AppStrings.t('yesConnectMe'))),
                              TextButton(
                                  onPressed: () => setState(() => _pending = null), child: Text(AppStrings.t('notNow'))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
                            enabled: !_escalated,
                            decoration: InputDecoration(hintText: AppStrings.t('typeMessage')),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          onPressed: _escalated || _sending ? null : _send,
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
