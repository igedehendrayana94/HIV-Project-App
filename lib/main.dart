import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/local_notifications.dart';
import 'core/locale_state.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'shared/i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotifications.init();
  runApp(const ProviderScope(child: MediCareHivApp()));
}

class MediCareHivApp extends ConsumerWidget {
  const MediCareHivApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(localeProvider);
    return MaterialApp.router(
      title: AppStrings.t('appName'),
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
