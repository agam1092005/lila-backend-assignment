import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'theme_preference';
  static const String _lightBlueValue = 'light_blue';
  static const String _darkBlueValue = 'dark_blue';

  bool _isDarkBlue = false;

  bool get isDarkBlue => _isDarkBlue;

  ThemeData get currentTheme => _isDarkBlue ? darkBlueTheme : lightBlueTheme;

  // Light Blue Theme
  static final ThemeData lightBlueTheme = ThemeData(
    primaryColor: const Color(0xFF2196F3),
    scaffoldBackgroundColor: const Color(0xFFE3F2FD),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2196F3),
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.light,
    ),
  );

  // Dark Blue Theme
  static final ThemeData darkBlueTheme = ThemeData(
    primaryColor: const Color(0xFF1976D2),
    scaffoldBackgroundColor: const Color(0xFF0D47A1),
    cardColor: const Color(0xFF1565C0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1976D2),
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: Brightness.dark,
    ),
  );

  /// Load saved theme preference from shared_preferences
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    
    if (savedTheme == _darkBlueValue) {
      _isDarkBlue = true;
    } else {
      // Default to Light Blue if no preference saved
      _isDarkBlue = false;
    }
    
    notifyListeners();
  }

  /// Toggle between Light Blue and Dark Blue themes
  Future<void> toggleTheme() async {
    _isDarkBlue = !_isDarkBlue;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      _isDarkBlue ? _darkBlueValue : _lightBlueValue,
    );
    
    notifyListeners();
  }
}
