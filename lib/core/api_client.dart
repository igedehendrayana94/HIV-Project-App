import 'package:dio/dio.dart';
import '../shared/i18n.dart';
import 'token_storage.dart';

// Same origin as the web app's own /api routes — HIV-Project-Web doubles as this app's
// backend (see HIV-Project/CLAUDE.md). Override for local dev against `next dev` with:
// flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
const _defaultBaseUrl = 'https://hiv-project-web.vercel.app/api';
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

// One shared Dio instance (mirrors src/lib/db.ts's single shared Prisma client) — every
// request automatically carries the stored Bearer token, and a 401 clears it so the next
// screen read picks up "logged out" instead of quietly retrying with a dead token.
final dio = Dio(BaseOptions(baseUrl: apiBaseUrl))
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        // The web app's chat routes read locale from a cookie (LanguageToggle) — this app
        // has no cookie jar, so it sends its own locale here instead (see
        // HIV-Project-Web's lib/serverTranslate.ts, header takes priority over the cookie).
        options.headers['X-Locale'] = AppStrings.locale == AppLocale.id ? 'id' : 'en';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await TokenStorage.clear();
        }
        handler.next(error);
      },
    ),
  );

// Every API error route returns { error: string } (see any src/app/api/**/route.ts in the
// web app) — this pulls that out consistently instead of every call site re-parsing it.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  return AppStrings.t('somethingWentWrong');
}
