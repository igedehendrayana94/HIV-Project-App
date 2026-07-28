import 'package:flutter/material.dart';

// Mirrors RECOMMENDATIONS in src/lib/screeningModel.ts exactly — static clinical copy, not
// admin-customizable (unlike DOMAINS/questions), so a hand-kept duplicate here carries none
// of the drift risk that made GET /api/screening/domains necessary for the question set.
class RiskInfo {
  final String label;
  final String emoji;
  final Color color;
  final List<String> recommendations;
  final String actions;
  const RiskInfo(this.label, this.emoji, this.color, this.recommendations, this.actions);
}

const Map<String, RiskInfo> riskInfo = {
  'LOW': RiskInfo('Low Risk', '🟢', Colors.green, [
    'Give appreciation.',
    'Maintain compliance.',
    'Re-educate the importance of taking ARVs on time.',
    'Turn on medication reminders when needed.',
  ], 'Continue ARV, education, routine control.'),
  'MEDIUM': RiskInfo('Medium Risk', '🟡', Colors.amber, [
    'Compliance counseling.',
    'Identify the cause of forgetting or being late.',
    'Involve the PMO or family if the patient agrees.',
    'Schedule an evaluation in advance.',
  ], "Doctor's evaluation, examination according to domain, ARV will continue unless there are other instructions."),
  'HIGH': RiskInfo('High Risk', '🟠', Colors.orange, [
    'Intensive counseling.',
    'Identify barriers (side effects, stigma, access to medications, transportation costs, jobs).',
    'Consider a quicker revisit.',
    'Evaluate viral load according to guidelines when available.',
  ], 'Evaluate the doctor as soon as possible, laboratory examinations according to the domain, consider evaluation of the regimen when toxicity or therapy failure is suspected.'),
  'EMERGENCY': RiskInfo('Emergency', '🔴', Colors.red, [
    'Multidisciplinary counseling.',
    'Evaluation of the risk of therapy failure.',
    'Evaluation of viral load and CD4 according to clinical indications.',
    'Develop a compliance improvement plan before considering regime changes.',
  ], 'Immediately refer to the hospital/emergency room, perform emergency handling according to the facility, and evaluate the regimen by a doctor if necessary.'),
};
