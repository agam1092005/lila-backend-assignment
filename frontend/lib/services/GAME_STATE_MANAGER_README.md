# GameStateManager Documentation

## Overview

The `GameStateManager` handles real-time game state updates from the Nakama match server via WebSocket. It listens for state updates, player disconnections, move rejections, and error messages, providing streams for the UI to consume.

## Features

- **Real-time State Updates**: Receives and parses game state updates from the server
- **Connection Management**: Maintains WebSocket connection with automatic reconnection
- **Player Disconnection Handling**: Detects and notifies when players disconnect
- **Error Handling**: Captures and streams error messages and move rejections
- **Reconnection Logic**: Implements exponential backoff reconnection (1s, 2s, 4s, 8s, 16s)
- **Connection Status**: Provides connection status stream for UI feedback

## Usage

### 1. Initialize the GameStateManager

```dart
final gameStateManager = GameStateManager(
  host: 'your-nakama-server.com',
  port: 7350,
  ssl: true,
);
```

### 2. Connect to a Match

After matchmaking completes and you have a `Match` object:

```dart
await gameStateManager.connectToMatch(
  session: session,  // Nakama session from AuthService
  match: match,      // Match object from MatchmakingService
);
```

### 3. Listen to Game State Updates

```dart
gameStateManager.gameStateStream.listen((gameState) {
  // Update UI with new game state
  print('Current turn: ${gameState.currentTurn}');
  print('Board: ${gameState.board}');
  print('Outcome: ${gameState.outcome}');
  
  if (gameState.isTimerMode) {
    print('Timer remaining: ${gameState.timerRemaining}s');
  }
  
  if (gameState.isGameOver) {
    print('Game ended: ${gameState.outcome}');
  }
});
```

### 4. Listen to Connection Status

```dart
gameStateManager.connectionStatusStream.listen((status) {
  switch (status) {
    case ConnectionStatus.connecting:
      // Show "Connecting..." indicator
      break;
    case ConnectionStatus.connected:
      // Hide loading indicator, show game
      break;
    case ConnectionStatus.reconnecting:
      // Show "Reconnecting..." indicator
      break;
    case ConnectionStatus.disconnected:
      // Show "Disconnected" message
      break;
    case ConnectionStatus.error:
      // Show error message
      break;
  }
});
```

### 5. Listen to Player Disconnections

```dart
gameStateManager.playerDisconnectedStream.listen((playerId) {
  // Show notification that player disconnected
  print('Player $playerId disconnected');
});
```

### 6. Listen to Errors

```dart
gameStateManager.errorStream.listen((errorMessage) {
  // Show error dialog or snackbar
  print('Error: $errorMessage');
});
```

### 7. Disconnect from Match

When leaving the game or when the game ends:

```dart
await gameStateManager.disconnect();
```

### 8. Dispose

When the GameStateManager is no longer needed:

```dart
gameStateManager.dispose();
```

## Message Types Handled

The GameStateManager handles the following message types from the server:

### 1. state_update
Contains the complete game state including board, current turn, players, outcome, and timer.

```json
{
  "type": "state_update",
  "board": [["X", "", "O"], ["", "X", ""], ["O", "", ""]],
  "currentTurn": "X",
  "player1": {
    "userId": "user1",
    "username": "Player1",
    "symbol": "X",
    "sessionId": "session1"
  },
  "player2": {
    "userId": "user2",
    "username": "Player2",
    "symbol": "O",
    "sessionId": "session2"
  },
  "outcome": "ongoing",
  "timerRemaining": 25
}
```

### 2. player_disconnected
Notifies when a player disconnects from the match.

```json
{
  "type": "player_disconnected",
  "playerId": "user123"
}
```

### 3. move_rejected
Sent when a move is rejected by the server.

```json
{
  "type": "move_rejected",
  "reason": "Not your turn"
}
```

### 4. error
Generic error message from the server.

```json
{
  "type": "error",
  "message": "An error occurred"
}
```

## Connection Status States

- **disconnected**: Not connected to any match
- **connecting**: Attempting to connect to a match
- **connected**: Successfully connected and receiving updates
- **reconnecting**: Connection lost, attempting to reconnect
- **error**: Connection failed after max reconnection attempts

## Reconnection Behavior

The GameStateManager implements automatic reconnection with exponential backoff:

1. First attempt: 1 second delay
2. Second attempt: 2 seconds delay
3. Third attempt: 4 seconds delay
4. Fourth attempt: 8 seconds delay
5. Fifth attempt: 16 seconds delay
6. After 5 failed attempts: Give up and set status to `error`

## Example: Complete Integration

```dart
class GameScreen extends StatefulWidget {
  final Session session;
  final Match match;

  const GameScreen({
    required this.session,
    required this.match,
    Key? key,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameStateManager _gameStateManager;
  GameState? _currentGameState;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    
    _gameStateManager = GameStateManager(
      host: 'your-server.com',
      port: 7350,
      ssl: true,
    );

    _setupListeners();
    _connectToMatch();
  }

  void _setupListeners() {
    _gameStateManager.gameStateStream.listen((gameState) {
      setState(() {
        _currentGameState = gameState;
      });
    });

    _gameStateManager.connectionStatusStream.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });

    _gameStateManager.errorStream.listen((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    });

    _gameStateManager.playerDisconnectedStream.listen((playerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Player disconnected')),
      );
    });
  }

  Future<void> _connectToMatch() async {
    await _gameStateManager.connectToMatch(
      session: widget.session,
      match: widget.match,
    );
  }

  @override
  void dispose() {
    _gameStateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionStatus != ConnectionStatus.connected) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(_getConnectionStatusText()),
            ],
          ),
        ),
      );
    }

    if (_currentGameState == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tic-Tac-Toe'),
      ),
      body: Column(
        children: [
          // Display current turn
          Text('Current Turn: ${_currentGameState!.currentTurn}'),
          
          // Display timer if in timer mode
          if (_currentGameState!.isTimerMode)
            Text('Time: ${_currentGameState!.timerRemaining}s'),
          
          // Display board
          // ... (GameBoard widget)
          
          // Display outcome if game is over
          if (_currentGameState!.isGameOver)
            Text('Result: ${_currentGameState!.outcome}'),
        ],
      ),
    );
  }

  String _getConnectionStatusText() {
    switch (_connectionStatus) {
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Connection Error';
      default:
        return '';
    }
  }
}
```

## Requirements Validated

This implementation validates the following requirements:

- **4.1**: Game state updates are received and processed in real-time
- **4.2**: Game state updates are rendered within 50ms (via stream)
- **4.3**: Current turn is displayed via GameState.currentTurn
- **4.4**: Player identities are displayed via GameState.player1/player2
- **6.3**: Player disconnections are detected and notified
- **13.4**: Runtime modules can send messages to clients (received here)

## Notes

- The GameStateManager does NOT send moves to the server - use `MoveController` for that
- Always call `dispose()` when the GameStateManager is no longer needed
- The manager automatically handles reconnection, but after 5 failed attempts it gives up
- All streams are broadcast streams, so multiple listeners can subscribe
