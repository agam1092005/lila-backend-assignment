import 'package:flutter/material.dart';
import 'package:frontend/services/theme_manager.dart';

class ThemeToggle extends StatelessWidget {
  final ThemeManager themeManager;

  const ThemeToggle({
    super.key,
    required this.themeManager,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        themeManager.isDarkBlue ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () {
        themeManager.toggleTheme();
      },
      tooltip: 'Toggle Theme',
    );
  }
}
