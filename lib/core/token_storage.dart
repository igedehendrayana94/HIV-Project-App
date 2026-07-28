import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Keychain/Keystore-backed — the mobile equivalent of the web app's httpOnly session cookie
// (src/lib/auth.ts's COOKIE). Single place so the interceptor and auth screens agree on
// where the token lives.
class TokenStorage {
  TokenStorage._();
  static final _storage = FlutterSecureStorage();
  static const _key = 'medicare_hiv_token';

  static Future<void> save(String token) => _storage.write(key: _key, value: token);
  static Future<String?> read() => _storage.read(key: _key);
  static Future<void> clear() => _storage.delete(key: _key);
}
