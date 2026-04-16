import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeManager', () {
    setUp(() {
      // Initialize shared preferences with mock values
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to Light Blue theme', () async {
      final themeManager = ThemeManager();
      await themeManager.loadTheme();
      
      expect(themeManager.isDarkBlue, false);
      expect(themeManager.currentTheme, ThemeManager.lightBlueTheme);
    });

    test('toggles between Light Blue and Dark Blue themes', () async {
      final themeManager = ThemeManager();
      await themeManager.loadTheme();
      
      expect(themeManager.isDarkBlue, false);
      
      await themeManager.toggleTheme();
      expect(themeManager.isDarkBlue, true);
      expect(themeManager.currentTheme, ThemeManager.darkBlueTheme);
      
      await themeManager.toggleTheme();
      expect(themeManager.isDarkBlue, false);
      expect(themeManager.currentTheme, ThemeManager.lightBlueTheme);
    });

    test('persists theme preference', () async {
      final themeManager1 = ThemeManager();
      await themeManager1.loadTheme();
      await themeManager1.toggleTheme();
      
      expect(themeManager1.isDarkBlue, true);
      
      // Create a new instance to simulate app restart
      final themeManager2 = ThemeManager();
      await themeManager2.loadTheme();
      
      expect(themeManager2.isDarkBlue, true);
    });

    test('loads saved Dark Blue theme preference', () async {
      SharedPreferences.setMockInitialValues({
        'theme_preference': 'dark_blue',
      });
      
      final themeManager = ThemeManager();
      await themeManager.loadTheme();
      
      expect(themeManager.isDarkBlue, true);
      expect(themeManager.currentTheme, ThemeManager.darkBlueTheme);
    });
  });
}
