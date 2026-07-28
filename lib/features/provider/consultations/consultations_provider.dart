import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'models.dart';

// Same queue GET the web app's ConsultationQueue.tsx and sidebar badge both poll — already
// ordered urgency-desc then oldest-first (see the route's own comment).
final consultationsProvider = FutureProvider<List<ConsultationSummary>>((ref) async {
  final res = await dio.get('/consultations');
  final list = res.data['consultations'] as List;
  return list.map((c) => ConsultationSummary.fromJson(c as Map<String, dynamic>)).toList();
});
