// Mirrors src/lib/i18n.ts's { key: { en, id } } dictionary shape — same pattern the web
// app already solved, kept in sync by hand rather than pulling in an ARB/gen-l10n toolchain
// for a project that already has a working home-grown one.
enum AppLocale { en, id }

const Map<String, Map<AppLocale, String>> _strings = {
  'appName': {AppLocale.en: 'Medi-Care HIV', AppLocale.id: 'Medi-Care HIV'},
  'login': {AppLocale.en: 'Log In', AppLocale.id: 'Masuk'},
  'signup': {AppLocale.en: 'Sign Up', AppLocale.id: 'Daftar'},
  'email': {AppLocale.en: 'Email', AppLocale.id: 'Email'},
  'password': {AppLocale.en: 'Password', AppLocale.id: 'Kata Sandi'},
  'name': {AppLocale.en: 'Full Name', AppLocale.id: 'Nama Lengkap'},
  'noAccount': {AppLocale.en: "Don't have an account? Sign up", AppLocale.id: 'Belum punya akun? Daftar'},
  'haveAccount': {AppLocale.en: 'Already have an account? Log in', AppLocale.id: 'Sudah punya akun? Masuk'},
  'signupPending': {
    AppLocale.en: 'Account created. An admin must approve it before you can log in.',
    AppLocale.id: 'Akun dibuat. Admin harus menyetujuinya sebelum Anda dapat masuk.',
  },
  'logout': {AppLocale.en: 'Log Out', AppLocale.id: 'Keluar'},
};

class AppStrings {
  static AppLocale locale = AppLocale.en;
  static String t(String key) => _strings[key]?[locale] ?? key;
}
