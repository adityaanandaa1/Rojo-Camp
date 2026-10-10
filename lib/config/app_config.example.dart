// lib/config/app_config.example.dart
//
// TEMPLATE — file ini AMAN di-commit ke repo publik, isinya cuma placeholder.
//
// Cara pakai:
// 1. Copy file ini, rename jadi "app_config.dart" (di folder yang sama)
// 2. Isi appScriptUrl dan syncToken dengan nilai asli kamu
// 3. app_config.dart (bukan file ini) yang sudah di-gitignore, jadi aman
//    nilai aslinya gak ikut ke-commit
//
// Kalau kamu baru clone repo ini dan lib/config/app_config.dart belum ada,
// itu artinya kamu perlu bikin dari template ini dulu.

class AppConfig {
  AppConfig._();

  static const String appScriptUrl = 'GANTI_DENGAN_URL_APPS_SCRIPT_KAMU';

  static const String syncToken =
      'GANTI_DENGAN_TOKEN_RAHASIA_MINIMAL_20_KARAKTER';

  static const String sheetsTabName = 'Rombongan';

  static const int httpTimeoutSeconds = 30;

  static bool get isConfigured =>
      appScriptUrl.isNotEmpty &&
      !appScriptUrl.startsWith('GANTI_') &&
      syncToken.isNotEmpty &&
      !syncToken.startsWith('GANTI_');
}
