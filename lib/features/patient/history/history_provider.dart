import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../screening/models.dart';

// GET /api/patients/me/history — a PATIENT session resolves its own patientId server-side
// and ignores the "me" path segment entirely, so any placeholder works here.
final screeningHistoryProvider = FutureProvider<List<ScreeningAssessment>>((ref) async {
  final res = await dio.get('/patients/me/history');
  final list = res.data['screeningAssessments'] as List;
  return list.map((a) => ScreeningAssessment.fromJson(a as Map<String, dynamic>)).toList();
});
