import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class RiskCount {
  final String overallRisk;
  final int count;
  RiskCount({required this.overallRisk, required this.count});
  factory RiskCount.fromJson(Map<String, dynamic> j) =>
      RiskCount(overallRisk: j['overallRisk'] as String, count: j['count'] as int);
}

class MyScreening {
  final int id;
  final String overallRisk;
  final DateTime createdAt;
  final String patientName;
  MyScreening({
    required this.id,
    required this.overallRisk,
    required this.createdAt,
    required this.patientName,
  });
  factory MyScreening.fromJson(Map<String, dynamic> j) => MyScreening(
        id: j['id'] as int,
        overallRisk: j['overallRisk'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        patientName: j['patientName'] as String,
      );
}

class MyReports {
  final List<RiskCount> distribution;
  final List<MyScreening> screenings;
  MyReports({required this.distribution, required this.screenings});
}

// GET /api/reports/mine — mirrors reports/page.tsx's MyScreeningsReport (own conducted
// screenings only), the non-admin branch of the web Reports page.
final myReportsProvider = FutureProvider<MyReports>((ref) async {
  final res = await dio.get('/reports/mine');
  return MyReports(
    distribution: (res.data['distribution'] as List)
        .map((d) => RiskCount.fromJson(d as Map<String, dynamic>))
        .toList(),
    screenings:
        (res.data['screenings'] as List).map((s) => MyScreening.fromJson(s as Map<String, dynamic>)).toList(),
  );
});
