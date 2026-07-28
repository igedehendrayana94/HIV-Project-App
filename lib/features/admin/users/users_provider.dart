import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'models.dart';

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  final res = await dio.get('/admin/users');
  final list = res.data['users'] as List;
  return list.map((u) => AdminUser.fromJson(u as Map<String, dynamic>)).toList();
});
