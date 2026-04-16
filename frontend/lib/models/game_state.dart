import 'player_info.dart';

/// GameState represents the complete state of a Tic-Tac-Toe game
class GameState {
  final List<List<String>> board; // 3x3 array, values: "", "X", "O"
  final String currentTurn; // "X" or "O"
  final PlayerInfo player1;
  final PlayerInfo player2;
  final String outcome; // "ongoing", "player1_wins", "player2_wins", "draw"
  final String gameMode; // "classic" or "timer"
  final int? timerRemaining; // seconds, only in timer mode

  GameState({
    required this.board,
    required this.currentTurn,
    required this.player1,
    required this.player2,
    required this.outcome,
    required this.gameMode,
    this.timerRemaining,
  });

  /// Create GameState from JSON
  factory GameState.fromJson(Map<String, dynamic> json) {
    // Parse board - handle both List<List<String>> and List<dynamic>
    final boardData = json['board'] as List<dynamic>? ?? [];
    final board = boardData.map((row) {
      if (row is List) {
        return row.map((cell) => cell.toString()).toList();
      }
      return <String>[];
    }).toList();

    return GameState(
      board: board,
      currentTurn: json['currentTurn'] as String? ?? 'X',
      player1: PlayerInfo.fromJson(json['player1'] as Map<String, dynamic>? ?? {}),
      player2: PlayerInfo.fromJson(json['player2'] as Map<String, dynamic>? ?? {}),
      outcome: json['outcome'] as String? ?? 'ongoing',
      gameMode: json['gameMode'] as String? ?? 'classic',
      timerRemaining: json['timerRemaining'] as int?,
    );
  }

  /// Convert GameState to JSON
  Map<String, dynamic> toJson() {
    return {
      'board': board,
      'currentTurn': currentTurn,
      'player1': player1.toJson(),
      'player2': player2.toJson(),
      'outcome': outcome,
      'gameMode': gameMode,
      'timerRemaining': timerRemaining,
    };
  }

  /// Check if the game has ended
  bool get isGameOver => outcome != 'ongoing';

  /// Check if it's timer mode
  bool get isTimerMode => gameMode == 'timer';

  /// Get the current player (whose turn it is)
  PlayerInfo get currentPlayer {
    return currentTurn == player1.symbol ? player1 : player2;
  }

  /// Get the opponent player
  PlayerInfo get opponentPlayer {
    return currentTurn == player1.symbol ? player2 : player1;
  }

  @override
  String toString() {
    return 'GameState(currentTurn: $currentTurn, outcome: $outcome, gameMode: $gameMode)';
  }
}
