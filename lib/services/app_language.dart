import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static const String _key = 'app_language';
  static const String defaultLanguage = 'pt-BR';

  // Idiomas suportados
  static const Map<String, String> supportedLanguages = {
    'pt-BR': 'Português (Brasil)',
    'en': 'English',
    'es': 'Español',
    'zh': '中文 (Mandarim)',
  };

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? defaultLanguage;
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }
}