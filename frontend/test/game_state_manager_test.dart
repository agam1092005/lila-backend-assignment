import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/game_state.dart';
import 'package:frontend/models/player_info.dart';

void main() {
  group('GameState Model Tests', () {
    test('GameState.fromJson parses state_update message correctly', () {
      final json = {
        'type': 'state_update',
        'board': [
          ['X', '', 'O'],
          ['', 'X', ''],
          ['O', '', '']
        ],
        'currentTurn': 'X',
        'player1': {
          'userId': 'user1',
          'username': 'Player1',
          'symbol': 'X',
          'sessionId': 'session1'
        },
        'player2': {
          'userId': 'user2',
          'username': 'Player2',
          'symbol': 'O',
          'sessionId': 'session2'
        },
        'outcome': 'ongoing',
        'gameMode': 'classic',
        'timerRemaining': null,
      };

      final gameState = GameState.fromJson(json);

      expect(gameState.board.length, 3);
      expect(gameState.board[0][0], 'X');
      expect(gameState.board[0][2], 'O');
      expect(gameState.currentTurn, 'X');
      expect(gameState.player1.username, 'Player1');
      expect(gameState.player2.username, 'Player2');
      expect(gameState.outcome, 'ongoing');
      expect(gameState.gameMode, 'classic');
      expect(gameState.isGameOver, false);
      expect(gameState.isTimerMode, false);
    });

    test('GameState.fromJson handles timer mode correctly', () {
      final json = {
        'board': [
          ['', '', ''],
          ['', '', ''],
          ['', '', '']
        ],
        'currentTurn': 'X',
        'player1': {
          'userId': 'user1',
          'username': 'Player1',
          'symbol': 'X',
          'sessionId': 'session1'
        },
        'player2': {
          'userId': 'user2',
          'username': 'Player2',
          'symbol': 'O',
          'sessionId': 'session2'
        },
        'outcome': 'ongoing',
        'gameMode': 'timer',
        'timerRemaining': 25,
      };

      final gameState = GameState.fromJson(json);

      expect(gameState.gameMode, 'timer');
      expect(gameState.isTimerMode, true);
      expect(gameState.timerRemaining, 25);
    });

    test('GameState.isGameOver returns true when game has ended', () {
      final json = {
        'board': [
          ['X', 'X', 'X'],
          ['O', 'O', ''],
          ['', '', '']
        ],
        'currentTurn': 'X',
        'player1': {
          'userId': 'user1',
          'username': 'Player1',
          'symbol': 'X',
          'sessionId': 'session1'
        },
        'player2': {
          'userId': 'user2',
          'username': 'Player2',
          'symbol': 'O',
          'sessionId': 'session2'
        },
        'outcome': 'player1_wins',
        'gameMode': 'classic',
      };

      final gameState = GameState.fromJson(json);

      expect(gameState.isGameOver, true);
      expect(gameState.outcome, 'player1_wins');
    });

    test('GameState.currentPlayer returns correct player', () {
      final json = {
        'board': [
          ['', '', ''],
          ['', '', ''],
          ['', '', '']
        ],
        'currentTurn': 'O',
        'player1': {
          'userId': 'user1',
          'username': 'Player1',
          'symbol': 'X',
          'sessionId': 'session1'
        },
        'player2': {
          'userId': 'user2',
          'username': 'Player2',
          'symbol': 'O',
          'sessionId': 'session2'
        },
        'outcome': 'ongoing',
        'gameMode': 'classic',
      };

      final gameState = GameState.fromJson(json);

      expect(gameState.currentPlayer.symbol, 'O');
      expect(gameState.currentPlayer.username, 'Player2');
      expect(gameState.opponentPlayer.symbol, 'X');
      expect(gameState.opponentPlayer.username, 'Player1');
    });
  });

  group('PlayerInfo Model Tests', () {
    test('PlayerInfo.fromJson parses correctly', () {
      final json = {
        'userId': 'user123',
        'username': 'TestPlayer',
        'symbol': 'X',
        'sessionId': 'session456'
      };

      final playerInfo = PlayerInfo.fromJson(json);

      expect(playerInfo.userId, 'user123');
      expect(playerInfo.username, 'TestPlayer');
      expect(playerInfo.symbol, 'X');
      expect(playerInfo.sessionId, 'session456');
    });

    test('PlayerInfo.toJson converts correctly', () {
      final playerInfo = PlayerInfo(
        userId: 'user123',
        username: 'TestPlayer',
        symbol: 'O',
        sessionId: 'session456',
      );

      final json = playerInfo.toJson();

      expect(json['userId'], 'user123');
      expect(json['username'], 'TestPlayer');
      expect(json['symbol'], 'O');
      expect(json['sessionId'], 'session456');
    });
  });
}
