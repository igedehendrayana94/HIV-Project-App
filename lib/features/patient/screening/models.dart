import '../../../shared/i18n.dart';

// Mirrors src/lib/screeningModel.ts's Bilingual/Stage2Option/Symptom/Domain shapes exactly —
// parsed from GET /api/screening/domains rather than hardcoded, so admin-added
// ScreeningQuestion rows show up here automatically instead of drifting out of sync.
class Bilingual {
  final String en;
  final String id;
  Bilingual({required this.en, required this.id});
  factory Bilingual.fromJson(Map<String, dynamic> j) => Bilingual(en: j['en'] as String, id: j['id'] as String);
  String get text => AppStrings.locale == AppLocale.id ? id : en;
}

class Stage2Option {
  final Bilingual label;
  final int score;
  Stage2Option({required this.label, required this.score});
  factory Stage2Option.fromJson(Map<String, dynamic> j) =>
      Stage2Option(label: Bilingual.fromJson(j['label'] as Map<String, dynamic>), score: j['score'] as int);
}

class Symptom {
  final String key;
  final Bilingual question;
  final List<Stage2Option> stage2Options;
  final int? redFlagAtScore;
  Symptom({required this.key, required this.question, required this.stage2Options, this.redFlagAtScore});
  factory Symptom.fromJson(Map<String, dynamic> j) => Symptom(
        key: j['key'] as String,
        question: Bilingual.fromJson(j['question'] as Map<String, dynamic>),
        stage2Options: (j['stage2Options'] as List).map((o) => Stage2Option.fromJson(o as Map<String, dynamic>)).toList(),
        redFlagAtScore: j['redFlagAtScore'] as int?,
      );
}

class Domain {
  final String key;
  final Bilingual label;
  final List<Symptom> symptoms;
  Domain({required this.key, required this.label, required this.symptoms});
  factory Domain.fromJson(Map<String, dynamic> j) => Domain(
        key: j['key'] as String,
        label: Bilingual.fromJson(j['label'] as Map<String, dynamic>),
        symptoms: (j['symptoms'] as List).map((s) => Symptom.fromJson(s as Map<String, dynamic>)).toList(),
      );
}

// domainKey -> symptomKey -> { stage1, stage2 } — same shape POST /api/screening expects.
class SymptomAnswer {
  bool stage1;
  int? stage2;
  SymptomAnswer({this.stage1 = false, this.stage2});
  Map<String, dynamic> toJson() => {'stage1': stage1, if (stage2 != null) 'stage2': stage2};
}

class ScreeningAssessment {
  final int id;
  final String overallRisk;
  final bool redFlag;
  final DateTime createdAt;
  final Map<String, dynamic> domainScores;
  ScreeningAssessment({
    required this.id,
    required this.overallRisk,
    required this.redFlag,
    required this.createdAt,
    required this.domainScores,
  });
  factory ScreeningAssessment.fromJson(Map<String, dynamic> j) => ScreeningAssessment(
        id: j['id'] as int,
        overallRisk: j['overallRisk'] as String,
        redFlag: j['redFlag'] as bool,
        createdAt: DateTime.parse(j['createdAt'] as String),
        domainScores: j['domainScores'] as Map<String, dynamic>,
      );
}
