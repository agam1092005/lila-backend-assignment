# MoveController

## Overview

The `MoveController` handles player move input and submission to the Nakama server. It captures board cell tap events, sends move requests via Nakama match signals, handles move rejection errors, and prevents multiple simultaneous submissions.

## Requirements

Implements requirements:
- **3.1**: Server-authoritative move validation
- **3.5**: Move rejection error handling
- **15.2**: Error display to user

## Usage

### Initialization

```dart
final moveController = MoveController(
  socket: nakamaWebsocketClient,
  matchId: currentMatchId,
);
```

### Submitting a Move

```dart
// When user taps a board cell at position (row, col)
final success = await moveController.submitMove(row, col);

if (success) {
  // Move was sent to server
  // Wait for server response (state_update or move_rejected)
} else {
  // Move was rejected locally (invalid coordinates or submission in progress)
  // Error will be emitted on errorStream
}
```

### Listening for Errors

```dart
moveController.errorStream.listen((errorMessage) {
  // Display error to user (e.g., in a SnackBar or Dialog)
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorMessage)),
  );
});
```

### Integration with GameStateManager

The `MoveController` should be integrated with the `GameStateManager` to handle server responses:

```dart
// When GameStateManager receives a move_rejected message
gameStateManager.errorStream.listen((errorMessage) {
  if (errorMessage.contains('move')) {
    moveController.handleMoveRejection(errorMessage);
  }
});

// When GameStateManager receives a state_update message
gameStateManager.gameStateStream.listen((gameState) {
  moveController.handleMoveSuccess();
});
```

### Checking Submission Status

```dart
if (moveController.isSubmitting) {
  // A move is currently being processed
  // Disable UI or show loading indicator
}
```

### Cleanup

```dart
@override
void dispose() {
  moveController.dispose();
  super.dispose();
}
```

## Message Protocol

### Client to Server

The MoveController sends move requests to the server using the following format:

```json
{
  "type": "move",
  "row": 0-2,
  "col": 0-2
}
```

The message is sent via `sendMatchData` with op code `1`.

### Server to Client

The server responds with one of two message types:

**Success (state_update):**
```json
{
  "type": "state_update",
  "board": [...],
  "currentTurn": "X" | "O",
  ...
}
```

**Failure (move_rejected):**
```json
{
  "type": "move_rejected",
  "reason": "Not your turn" | "Position occupied" | "Game ended"
}
```

## Validation

The MoveController performs client-side validation before sending moves to the server:

1. **Coordinate Range**: Row and column must be between 0 and 2
2. **Submission Lock**: Only one move can be submitted at a time

All other validation (turn order, position occupancy, game status) is performed server-side.

## Error Handling

The MoveController emits errors on the `errorStream` for:

- Invalid coordinates (out of range)
- Multiple simultaneous submissions
- Network errors when sending moves
- Server-side move rejections (via `handleMoveRejection`)

## Example: Complete Integration

```dart
class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameStateManager gameStateManager;
  late MoveController moveController;
  StreamSubscription? errorSubscription;
  StreamSubscription? stateSubscription;

  @override
  void initState() {
    super.initState();
    
    // Initialize managers
    gameStateManager = GameStateManager(
      host: 'your-server.com',
      port: 7351,
      ssl: true,
    );
    
    moveController = MoveController(
      socket: gameStateManager.socket,
      matchId: widget.matchId,
    );
    
    // Listen for errors
    errorSubscription = moveController.errorStream.listen((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    });
    
    // Listen for state updates
    stateSubscription = gameStateManager.gameStateStream.listen((state) {
      moveController.handleMoveSuccess();
      setState(() {
        // Update UI with new state
      });
    });
  }

  void onCellTapped(int row, int col) async {
    if (moveController.isSubmitting) {
      return; // Ignore taps while submitting
    }
    
    await moveController.submitMove(row, col);
  }

  @override
  void dispose() {
    errorSubscription?.cancel();
    stateSubscription?.cancel();
    moveController.dispose();
    gameStateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBoard(
        onCellTapped: onCellTapped,
        isSubmitting: moveController.isSubmitting,
      ),
    );
  }
}
```

## Testing

Unit tests for the MoveController are located in `test/move_controller_test.dart`.

The tests verify:
- Coordinate validation logic
- Message format
- Error message content
- Integration requirements

Integration tests with a real Nakama server should be performed separately to verify:
- Move submission and server response handling
- Error handling for various rejection reasons
- Submission locking behavior
