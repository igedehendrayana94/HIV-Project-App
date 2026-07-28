import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'models.dart';

final domainsProvider = FutureProvider<List<Domain>>((ref) async {
  final res = await dio.get('/screening/domains');
  final domains = (res.data['domains'] as List).map((d) => Domain.fromJson(d as Map<String, dynamic>)).toList();
  return domains;
});
