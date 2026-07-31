import 'package:flutter/material.dart';

// Brand palette v2 (2026-07-31 — "bold/vibrant" direction, Duolingo/Cash App reference
// class): the first pass (soft pastel D68888 seed, muted containers) read as "too simple,
// old-school, low contrast" — real user feedback, not a guess. Fix: a solid, saturated,
// AA-passing rose (#C2185B, 5.87:1 vs white — audited, see below) drives every primary
// surface as a FLAT FILL, not a tonal container tint; body text goes back to true
// black/white for maximum contrast instead of soft grey-on-pastel; cards are bright white
// with a visible shadow instead of a barely-different pastel-on-pastel container color.
// D68888/BF8080 (the original brand pair) survive as secondary/decorative accents only —
// never as a primary action fill anymore, since that's exactly what read as washed-out.
class AppRadius {
  static const card = 20.0;
  static const button = 999.0; // pill
  static const chip = 999.0;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

const kVibrantPrimary = Color(0xFFC2185B); // Material Pink 800 — 5.87:1 vs white
const kVibrantPrimaryDark = Color(0xFFAD1457); // pressed/dark variant
const kBrandSoft = Color(0xFFD68888); // original brand pink — decorative/secondary only
const kBrandSoftAlt = Color(0xFFBF8080);
const kSurface = Color(0xFFFFFFFF);
const kBackground = Color(0xFFFCFAFB);

final _colorScheme = ColorScheme.fromSeed(
  seedColor: kVibrantPrimary,
  brightness: Brightness.light,
).copyWith(
  primary: kVibrantPrimary,
  onPrimary: Colors.white,
  secondary: kBrandSoftAlt,
  surface: kSurface,
  onSurface: Colors.black,
);

// App-wide push/pop transition — every Navigator.push and go_router route change gets this
// automatically (set once here, not per-screen) since ThemeData.pageTransitionsTheme is
// consulted by the platform's default PageRoute builder. Slide-up + fade reads as far more
// "alive" than the stock Cupertino/Material slide, directly answering "visible animation on
// any action, not just list entrances."
final _pageTransitionsTheme = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values) platform: const _SlideUpFadeTransitionsBuilder(),
  },
);

class _SlideUpFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideUpFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

final appTheme = ThemeData(
  colorScheme: _colorScheme,
  scaffoldBackgroundColor: kBackground,
  useMaterial3: true,
  visualDensity: VisualDensity.comfortable,
  pageTransitionsTheme: _pageTransitionsTheme,
  splashFactory: InkSparkle.splashFactory,
  appBarTheme: const AppBarTheme(
    backgroundColor: kBackground,
    foregroundColor: Colors.black,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 3,
    shadowColor: kVibrantPrimary.withValues(alpha: 0.16),
    color: kSurface,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kVibrantPrimary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: kVibrantPrimary.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kVibrantPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      side: const BorderSide(color: kVibrantPrimary, width: 1.5),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kVibrantPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? kVibrantPrimary : null,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? kVibrantPrimary.withValues(alpha: 0.4) : null,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF7F0F2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kVibrantPrimary, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.black54),
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: kSurface,
    elevation: 8,
    shadowColor: kVibrantPrimary.withValues(alpha: 0.2),
    height: 68,
    indicatorColor: kVibrantPrimary,
    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: states.contains(WidgetState.selected) ? kVibrantPrimary : Colors.black54,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected) ? Colors.white : Colors.black54,
      ),
    ),
  ),
  listTileTheme: ListTileThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2, color: Colors.black),
    titleMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.3, color: Colors.black),
    bodyMedium: TextStyle(height: 1.5, color: Colors.black87),
    bodySmall: TextStyle(height: 1.45, color: Colors.black54),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.3, color: Colors.black54),
  ),
);
