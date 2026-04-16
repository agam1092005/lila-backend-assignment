import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/main_menu_screen.dart';
import 'package:frontend/screens/matchmaking_screen.dart';
import 'package:frontend/screens/game_screen.dart';
import 'package:frontend/services/theme_manager.dart';

void main() {
  group('Responsive Screen Tests', () {
    late ThemeManager themeManager;

    setUp(() {
      themeManager = ThemeManager();
    });

    testWidgets('MainMenuScreen adapts to mobile screen size', (WidgetTester tester) async {
      // Set mobile screen size (480x800)
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(themeManager: themeManager),
        ),
      );

      // Verify the screen renders without errors
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(find.text('Multiplayer Tic-Tac-Toe'), findsOneWidget);
      expect(find.text('Find Match'), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);

      // Reset for other tests
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('MainMenuScreen adapts to desktop screen size', (WidgetTester tester) async {
      // Set desktop screen size (1024x768)
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(themeManager: themeManager),
        ),
      );

      // Verify the screen renders without errors
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(find.text('Multiplayer Tic-Tac-Toe'), findsOneWidget);

      // Verify centered layout with max width constraint
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Center),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, 1200.0);

      // Reset for other tests
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('MatchmakingScreen adapts to mobile screen size', (WidgetTester tester) async {
      // Set mobile screen size (480x800)
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: MatchmakingScreen(),
        ),
      );

      // Verify the screen renders without errors
      expect(find.byType(MatchmakingScreen), findsOneWidget);
      expect(find.text('Select Game Mode'), findsOneWidget);
      expect(find.text('Classic Mode'), findsOneWidget);
      expect(find.text('Timer Mode'), findsOneWidget);

      // Reset for other tests
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('MatchmakingScreen adapts to desktop screen size', (WidgetTester tester) async {
      // Set desktop screen size (1024x768)
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: MatchmakingScreen(),
        ),
      );

      // Verify the screen renders without errors
      expect(find.byType(MatchmakingScreen), findsOneWidget);
      expect(find.text('Select Game Mode'), findsOneWidget);

      // Reset for other tests
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('GameScreen adapts to mobile screen size', (WidgetTester tester) async {
      // Set mobile screen size (480x800)
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(),
        ),
      );

      // Verify the screen renders without errors
      expect(find.byType(GameScreen), findsOneWidget);

      // Reset for other tests
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('GameScreen adapts to desktop screen size', (WidgetTester tester) async {
      // Set desktop screen size (1024x768)
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(),
        ),
      );

      // Verify the screen renders without errors
      expect(find.byType(GameScreen), findsOneWidget);

      // Reset for other tests
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('Screens handle minimum mobile width (320px)', (WidgetTester tester) async {
      // Set minimum mobile screen size (320x568)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(themeManager: themeManager),
        ),
      );

      // Verify the screen renders without errors at minimum width
      expect(find.byType(MainMenuScreen), findsOneWidget);
      expect(find.text('Multiplayer Tic-Tac-Toe'), findsOneWidget);

      // Reset for other tests
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('Screens handle large desktop width (1920px)', (WidgetTester tester) async {
      // Set large desktop screen size (1920x1080)
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(themeManager: themeManager),
        ),
      );

      // Verify the screen renders without errors at large width
      expect(find.byType(MainMenuScreen), findsOneWidget);

      // Verify content is constrained to max width
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Center),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, 1200.0);

      // Reset for other tests
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
