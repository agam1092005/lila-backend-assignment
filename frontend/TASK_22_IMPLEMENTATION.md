# Task 22: Error Handling Implementation

## Overview

This document describes the comprehensive error handling implementation for the Flutter multiplayer Tic-Tac-Toe app. All services now include robust error handling with user-friendly error messages, retry logic, and proper error recovery.

## Implementation Summary

### 1. AuthService Error Handling

**Features Implemented:**
- ✅ Connection error detection with user-friendly messages
- ✅ Exponential backoff retry (1s, 2s, 4s, 8s, 30s)
- ✅ Detailed error messages with retry attempt information
- ✅ Error stream for UI consumption
- ✅ Session expiration handling with automatic re-authentication
- ✅ Graceful handling of storage failures

**Error Types Handled:**
- Network/connection errors (SocketException, NetworkException)
- Timeout errors
- Authentication failures
- Session expiration
- Storage failures (non-critical)

**New API:**
```dart
// Error class
class AuthError {
  final String message;
  final bool canRetry;
  final int? retryAttempt;
  final int? maxRetries;
}

// Error stream
Stream<AuthError> get errorStream
```

**Error Messages:**
- "Cannot connect to game server. Please check your internet connection."
- "Connection timed out. The server may be unavailable."
- "Authentication failed: [details]. Retrying in X seconds... (Attempt Y/Z)"
- "Session expired and re-authentication failed. Please restart the app."

### 2. MatchmakingService Error Handling

**Features Implemented:**
- ✅ Connection error detection
- ✅ Timeout error handling (60 seconds)
- ✅ Cancellation support
- ✅ Error stream for UI consumption
- ✅ Retry capability
- ✅ Graceful cleanup on errors

**Error Types Handled:**
- Connection errors
- Timeout errors (60 seconds)
- Server errors
- Cancellation
- Match join failures

**New API:**
```dart
// Error class
class MatchmakingError {
  final String message;
  final bool canRetry;
  final MatchmakingErrorType type;
}

enum MatchmakingErrorType {
  connection,
  timeout,
  serverError,
  cancelled,
  unknown,
}

// Error stream
Stream<MatchmakingError> get errorStream
```

**Error Messages:**
- "Cannot connect to matchmaking server. Please check your internet connection."
- "Matchmaking timed out after 60 seconds. No opponent found. Please try again."
- "Failed to join match: [details]"
- "Already searching for a match. Please wait or cancel the current search."

### 3. GameStateManager Error Handling

**Features Implemented:**
- ✅ Connection error detection
- ✅ Automatic reconnection with exponential backoff (1s, 2s, 4s, 8s, 16s)
- ✅ Maximum 5 reconnection attempts
- ✅ Connection status tracking and display
- ✅ Error stream for UI consumption
- ✅ Graceful disconnection handling
- ✅ Empty message validation

**Error Types Handled:**
- Connection errors
- WebSocket disconnections
- Message parsing errors
- Reconnection failures

**Connection Status:**
- `disconnected`: Not connected to match
- `connecting`: Establishing connection
- `connected`: Successfully connected
- `reconnecting`: Attempting to reconnect
- `error`: Connection failed

**Error Messages:**
- "Cannot connect to game server. Please check your internet connection."
- "Connection lost. Attempting to reconnect..."
- "Reconnecting... (Attempt X/5, waiting Ys)"
- "Failed to reconnect after 5 attempts. Please return to the main menu and try again."
- "Failed to parse match data: [details]"

### 4. MoveController Error Handling

**Features Implemented:**
- ✅ Connection error detection
- ✅ Move validation error display
- ✅ Duplicate submission prevention
- ✅ User-friendly error messages
- ✅ Error stream for UI consumption

**Error Types Handled:**
- Connection errors during move submission
- Invalid coordinates
- Duplicate submissions
- Network errors

**Error Messages:**
- "Cannot send move: Connection lost. Please check your internet connection."
- "Please wait for the current move to complete"
- "Invalid move coordinates"
- "Failed to send move: [details]"

### 5. Error Dialog Widget

**Features Implemented:**
- ✅ Reusable error dialog component
- ✅ Retry action support
- ✅ Connection status indicator
- ✅ Pre-configured error types

**Usage Examples:**

```dart
// Show generic error
ErrorDialog.show(
  context: context,
  title: 'Error',
  message: 'Something went wrong',
  canRetry: true,
  onRetry: () => retryOperation(),
);

// Show connection error
ErrorDialog.showConnectionError(
  context: context,
  onRetry: () => reconnect(),
);

// Show timeout error
ErrorDialog.showTimeoutError(
  context: context,
  message: 'Matchmaking timed out',
  onRetry: () => retryMatchmaking(),
);

// Show move rejection
ErrorDialog.showMoveRejectionError(
  context: context,
  reason: 'Not your turn',
);

// Connection status indicator
ConnectionStatusIndicator(
  isConnected: gameStateManager.isConnected,
  isReconnecting: gameStateManager.connectionStatus == ConnectionStatus.reconnecting,
  statusMessage: 'Reconnecting...',
)
```

## Error Handling Patterns

### 1. Try-Catch Blocks

All async operations are wrapped in try-catch blocks:

```dart
try {
  // Async operation
  await someOperation();
} catch (e) {
  // Determine error type
  String errorMessage;
  if (e.toString().contains('SocketException')) {
    errorMessage = 'Connection error';
  } else {
    errorMessage = 'Operation failed: $e';
  }
  
  // Emit error to stream
  _errorController.add(errorMessage);
  
  // Rethrow if needed
  rethrow;
}
```

### 2. Exponential Backoff Retry

```dart
static const List<int> _retryDelays = [1, 2, 4, 8, 30];
int _retryAttempt = 0;

if (_retryAttempt < _retryDelays.length) {
  final delay = _retryDelays[_retryAttempt];
  _retryAttempt++;
  
  await Future.delayed(Duration(seconds: delay));
  return authenticate(); // Retry
}
```

### 3. Error Streams

All services expose error streams for UI consumption:

```dart
final _errorController = StreamController<ErrorType>.broadcast();
Stream<ErrorType> get errorStream => _errorController.stream;
```

### 4. Graceful Cleanup

All services handle cleanup gracefully:

```dart
try {
  await cleanup();
} catch (e) {
  // Log but don't throw - cleanup should always succeed
  print('Warning: Error during cleanup: $e');
}
```

## UI Integration

### Listening to Error Streams

```dart
// In StatefulWidget initState
_authService.errorStream.listen((error) {
  ErrorDialog.show(
    context: context,
    message: error.message,
    canRetry: error.canRetry,
    onRetry: () => _authService.authenticate(),
  );
});

_matchmakingService.errorStream.listen((error) {
  ErrorDialog.show(
    context: context,
    message: error.message,
    canRetry: error.canRetry,
    onRetry: () => _retryMatchmaking(),
  );
});

_gameStateManager.errorStream.listen((errorMessage) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorMessage)),
  );
});

_moveController.errorStream.listen((errorMessage) {
  ErrorDialog.showMoveRejectionError(
    context: context,
    reason: errorMessage,
  );
});
```

### Connection Status Display

```dart
StreamBuilder<ConnectionStatus>(
  stream: gameStateManager.connectionStatusStream,
  builder: (context, snapshot) {
    final status = snapshot.data ?? ConnectionStatus.disconnected;
    return ConnectionStatusIndicator(
      isConnected: status == ConnectionStatus.connected,
      isReconnecting: status == ConnectionStatus.reconnecting,
    );
  },
)
```

## Testing Recommendations

### Manual Testing Scenarios

1. **Connection Errors:**
   - Disable network and attempt authentication
   - Verify error message displays
   - Verify retry logic works
   - Re-enable network and verify success

2. **Matchmaking Timeout:**
   - Start matchmaking without a second player
   - Wait 60 seconds
   - Verify timeout error displays
   - Verify retry option works

3. **Disconnection During Game:**
   - Start a game
   - Disable network
   - Verify reconnection attempts
   - Verify error message after max attempts
   - Re-enable network and verify reconnection

4. **Move Rejection:**
   - Attempt to move on opponent's turn
   - Verify error message displays
   - Attempt to move on occupied cell
   - Verify error message displays

### Unit Testing

```dart
test('AuthService retries with exponential backoff', () async {
  // Mock client to fail first 2 attempts
  final mockClient = MockNakamaClient();
  when(mockClient.authenticateDevice(deviceId: any))
    .thenThrow(Exception('Connection failed'))
    .thenThrow(Exception('Connection failed'))
    .thenAnswer((_) async => mockSession);
  
  final authService = AuthService(mockClient);
  final session = await authService.authenticate();
  
  expect(session, equals(mockSession));
  verify(mockClient.authenticateDevice(deviceId: any)).called(3);
});
```

## Requirements Validation

### Requirement 15.1: Connection Error Display
✅ **Implemented:** All services detect connection errors and display user-friendly messages via error streams and dialogs.

### Requirement 15.2: Move Rejection Display
✅ **Implemented:** MoveController emits move rejection errors to error stream, which can be displayed via ErrorDialog.showMoveRejectionError().

## Files Modified

1. `frontend/lib/services/auth_service.dart`
   - Added AuthError class
   - Added error stream
   - Enhanced error messages
   - Improved retry logic with user feedback

2. `frontend/lib/services/matchmaking_service.dart`
   - Added MatchmakingError class
   - Added error stream
   - Enhanced error messages
   - Improved timeout handling

3. `frontend/lib/services/game_state_manager.dart`
   - Enhanced connection error handling
   - Improved reconnection messages
   - Added empty message validation
   - Better error categorization

4. `frontend/lib/services/move_controller.dart`
   - Enhanced error messages
   - Better connection error detection

5. `frontend/lib/widgets/error_dialog.dart` (NEW)
   - Reusable error dialog component
   - Connection status indicator
   - Pre-configured error types

## Next Steps

To complete the error handling integration:

1. Update screens to listen to error streams
2. Display error dialogs when errors occur
3. Add connection status indicators to game screen
4. Test all error scenarios manually
5. Add unit tests for error handling logic

## Notes

- All async operations are now wrapped in try-catch blocks
- Error messages are user-friendly and actionable
- Retry logic is implemented where appropriate
- Connection status is tracked and can be displayed
- Cleanup operations are graceful and don't throw errors
- Error streams allow UI to react to errors in real-time
