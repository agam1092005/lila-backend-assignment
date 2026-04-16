// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/services/theme_manager.dart';

void main() {
  testWidgets('App loads with theme manager', (WidgetTester tester) async {
    // Create a theme manager for testing
    final themeManager = ThemeManager();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(themeManager: themeManager));

    // Verify that the main menu screen loads
    expect(find.text('Tic-Tac-Toe'), findsOneWidget);
    expect(find.text('Multiplayer Tic-Tac-Toe'), findsOneWidget);
  });
}
