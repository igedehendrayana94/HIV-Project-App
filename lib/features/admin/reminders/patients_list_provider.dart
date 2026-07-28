import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class PatientListItem {
  final int id;
  final String name;
  final int rank;
  PatientListItem({required this.id, required this.name, required this.rank});
  factory PatientListItem.fromJson(Map<String, dynamic> j) =>
      PatientListItem(id: j['id'] as int, name: j['name'] as String, rank: j['rank'] as int);
}

// GET /api/patients — Provider/Admin only. Used here as the patient picker for reminders;
// Admin's own patient-detail nav reuses the same Provider screen, so this is the only place
// Admin mobile needs a raw patient list.
final patientsListProvider = FutureProvider<List<PatientListItem>>((ref) async {
  final res = await dio.get('/patients');
  return (res.data['patients'] as List).map((p) => PatientListItem.fromJson(p as Map<String, dynamic>)).toList();
});
