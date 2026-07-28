class ConsultationSummary {
  final int id;
  final String status; // OPEN | IN_REVIEW | RESOLVED
  final String urgency; // ROUTINE | URGENT | EMERGENCY
  final DateTime createdAt;
  final String patientName;
  final String? assignedProviderName;

  ConsultationSummary({
    required this.id,
    required this.status,
    required this.urgency,
    required this.createdAt,
    required this.patientName,
    required this.assignedProviderName,
  });

  factory ConsultationSummary.fromJson(Map<String, dynamic> j) => ConsultationSummary(
        id: j['id'] as int,
        status: j['status'] as String,
        urgency: j['urgency'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        patientName: j['patientName'] as String,
        assignedProviderName: j['assignedProviderName'] as String?,
      );
}

class ConsultationThreadMessage {
  final int id;
  final String senderRole; // PATIENT | PROVIDER
  final String content;
  final String? senderName;
  final DateTime createdAt;

  ConsultationThreadMessage({
    required this.id,
    required this.senderRole,
    required this.content,
    required this.senderName,
    required this.createdAt,
  });

  factory ConsultationThreadMessage.fromJson(Map<String, dynamic> j) => ConsultationThreadMessage(
        id: j['id'] as int,
        senderRole: j['senderRole'] as String,
        content: j['content'] as String,
        senderName: (j['sender'] as Map<String, dynamic>?)?['name'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
