import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'api_client.dart';
import 'token_storage.dart';

// Mirrors src/lib/auth.ts's JWTPayload shape exactly — same token, same claims, decoded
// client-side here instead of server-side there.
class AuthUser {
  final int userId;
  final String email;
  final String name;
  final String role; // "ADMIN" | "PROVIDER" | "PATIENT"

  AuthUser({required this.userId, required this.email, required this.name, required this.role});

  factory AuthUser.fromToken(String token) {
    final claims = JwtDecoder.decode(token);
    return AuthUser(
      userId: claims['userId'] as int,
      email: claims['email'] as String,
      name: claims['name'] as String,
      role: claims['role'] as String,
    );
  }
}

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final token = await TokenStorage.read();
    if (token == null || JwtDecoder.isExpired(token)) return null;
    return AuthUser.fromToken(token);
  }

  Future<void> login(String email, String password) async {
    final res = await dio.post('/auth/login', data: {'email': email, 'password': password});
    final token = res.data['token'] as String;
    await TokenStorage.save(token);
    state = AsyncData(AuthUser.fromToken(token));
  }

  // Public self-signup always lands PENDING (see api/auth/signup) — no token comes back, no
  // session is created, the caller shows an approval-pending message and returns to login.
  Future<void> signup(String name, String email, String password) async {
    await dio.post('/auth/signup', data: {'name': name, 'email': email, 'password': password});
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? password,
    String? oldPassword,
  }) async {
    final res = await dio.patch('/account', data: {
      'name': name,
      'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
      if (password != null && password.isNotEmpty) 'oldPassword': oldPassword,
    });
    final token = res.data['token'] as String;
    await TokenStorage.save(token);
    state = AsyncData(AuthUser.fromToken(token));
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
