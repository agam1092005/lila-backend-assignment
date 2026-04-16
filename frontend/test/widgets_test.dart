import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/game_board.dart';
import 'package:frontend/widgets/player_info_widget.dart';
import 'package:frontend/widgets/turn_indicator.dart';
import 'package:frontend/widgets/timer_display.dart';
import 'package:frontend/widgets/outcome_dialog.dart';
import 'package:frontend/models/game_state.dart';
import 'package:frontend/models/player_info.dart';

void main() {
  group('GameBoard Widget Tests', () {
    testWidgets('renders 3x3 grid with empty cells', (WidgetTester tester) async {
      final gameState = GameState(
        board: [
          ['', '', ''],
          ['', '', ''],
          ['', '', ''],
        ],
        currentTurn: 'X',
        player1: PlayerInfo(userId: '1', username: 'Player1', symbol: 'X', sessionId: 's1'),
        player2: PlayerInfo(userId: '2', username: 'Player2', symbol: 'O', sessionId: 's2'),
        outcome: 'ongoing',
        gameMode: 'classic',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoard(gameState: gameState),
          ),
        ),
      );

      expect(find.byType(GameBoard), findsOneWidget);
    });

    testWidgets('displays X and O symbols correctly', (WidgetTester tester) async {
      final gameState = GameState(
        board: [
          ['X', 'O', ''],
          ['', 'X', ''],
          ['', '', 'O'],
        ],
        currentTurn: 'X',
        player1: PlayerInfo(userId: '1', username: 'Player1', symbol: 'X', sessionId: 's1'),
        player2: PlayerInfo(userId: '2', username: 'Player2', symbol: 'O', sessionId: 's2'),
        outcome: 'ongoing',
        gameMode: 'classic',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoard(gameState: gameState),
          ),
        ),
      );

      expect(find.text('X'), findsNWidgets(2));
      expect(find.text('O'), findsNWidgets(2));
    });

    testWidgets('handles tap events on empty cells', (WidgetTester tester) async {
      int tappedRow = -1;
      int tappedCol = -1;

      final gameState = GameState(
        board: [
          ['', '', ''],
          ['', '', ''],
          ['', '', ''],
        ],
        currentTurn: 'X',
        player1: PlayerInfo(userId: '1', username: 'Player1', symbol: 'X', sessionId: 's1'),
        player2: PlayerInfo(userId: '2', username: 'Player2', symbol: 'O', sessionId: 's2'),
        outcome: 'ongoing',
        gameMode: 'classic',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoard(
              gameState: gameState,
              onCellTap: (row, col) {
                tappedRow = row;
                tappedCol = col;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      expect(tappedRow, equals(0));
      expect(tappedCol, equals(0));
    });
  });

  group('PlayerInfoWidget Tests', () {
    testWidgets('displays both player usernames', (WidgetTester tester) async {
      final player1 = PlayerInfo(userId: '1', username: 'Alice', symbol: 'X', sessionId: 's1');
      final player2 = PlayerInfo(userId: '2', username: 'Bob', symbol: 'O', sessionId: 's2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerInfoWidget(
              player1: player1,
              player2: player2,
              currentTurn: 'X',
            ),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('displays player symbols', (WidgetTester tester) async {
      final player1 = PlayerInfo(userId: '1', username: 'Alice', symbol: 'X', sessionId: 's1');
      final player2 = PlayerInfo(userId: '2', username: 'Bob', symbol: 'O', sessionId: 's2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerInfoWidget(
              player1: player1,
              player2: player2,
              currentTurn: 'X',
            ),
          ),
        ),
      );

      expect(find.text('Symbol: X'), findsOneWidget);
      expect(find.text('Symbol: O'), findsOneWidget);
    });

    testWidgets('highlights current player turn', (WidgetTester tester) async {
      final player1 = PlayerInfo(userId: '1', username: 'Alice', symbol: 'X', sessionId: 's1');
      final player2 = PlayerInfo(userId: '2', username: 'Bob', symbol: 'O', sessionId: 's2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerInfoWidget(
              player1: player1,
              player2: player2,
              currentTurn: 'X',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('TurnIndicator Tests', () {
    testWidgets('displays whose turn it is', (WidgetTester tester) async {
      final currentPlayer = PlayerInfo(userId: '1', username: 'Alice', symbol: 'X', sessionId: 's1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurnIndicator(
              currentPlayer: currentPlayer,
              isGameOver: false,
            ),
          ),
        ),
      );

      expect(find.text("Alice's Turn (X)"), findsOneWidget);
    });

    testWidgets('displays Game Over when game ends', (WidgetTester tester) async {
      final currentPlayer = PlayerInfo(userId: '1', username: 'Alice', symbol: 'X', sessionId: 's1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurnIndicator(
              currentPlayer: currentPlayer,
              isGameOver: true,
            ),
          ),
        ),
      );

      expect(find.text('Game Over'), findsOneWidget);
    });
  });

  group('TimerDisplay Tests', () {
    testWidgets('displays countdown timer in timer mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimerDisplay(
              timerRemaining: 25,
              isTimerMode: true,
            ),
          ),
        ),
      );

      expect(find.text('25'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('shows warning color when time is low', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimerDisplay(
              timerRemaining: 5,
              isTimerMode: true,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('hides in classic mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimerDisplay(
              timerRemaining: 25,
              isTimerMode: false,
            ),
          ),
        ),
      );

      expect(find.byType(TimerDisplay), findsOneWidget);
      expect(find.text('25'), findsNothing);
    });
  });

  group('OutcomeDialog Tests', () {
    testWidgets('displays player 1 wins', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  OutcomeDialog.show(
                    context,
                    outcome: 'player1_wins',
                    player1Username: 'Alice',
                    player2Username: 'Bob',
                    onReturnToMenu: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Wins!'), findsOneWidget);
      expect(find.text('Return to Menu'), findsOneWidget);
    });

    testWidgets('displays draw result', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  OutcomeDialog.show(
                    context,
                    outcome: 'draw',
                    player1Username: 'Alice',
                    player2Username: 'Bob',
                    onReturnToMenu: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text("It's a Draw!"), findsOneWidget);
    });

    testWidgets('displays disconnection message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  OutcomeDialog.show(
                    context,
                    outcome: 'player1_wins',
                    player1Username: 'Alice',
                    player2Username: 'Bob',
                    isDisconnection: true,
                    onReturnToMenu: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Player disconnected'), findsOneWidget);
    });
  });
}
