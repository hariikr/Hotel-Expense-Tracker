import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, malayalam }

class LanguageService {
  static const String _languageKey = 'app_language';
  static AppLanguage _currentLanguage =
      AppLanguage.malayalam; // Default to Malayalam

  static AppLanguage get currentLanguage => _currentLanguage;

  /// Initialize language from saved preferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode == 'en') {
      _currentLanguage = AppLanguage.english;
    } else {
      // Default to Malayalam
      _currentLanguage = AppLanguage.malayalam;
    }
  }

  /// Set the app language
  static Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _languageKey,
      language == AppLanguage.malayalam ? 'ml' : 'en',
    );
  }

  /// Toggle between English and Malayalam
  static Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == AppLanguage.english
        ? AppLanguage.malayalam
        : AppLanguage.english;
    await setLanguage(newLanguage);
  }

  /// Get language code
  static String getLanguageCode() {
    return _currentLanguage == AppLanguage.malayalam ? 'ml' : 'en';
  }

  /// Get language name
  static String getLanguageName() {
    return _currentLanguage == AppLanguage.malayalam ? 'മലയാളം' : 'English';
  }
}
