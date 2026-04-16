# AuthService Documentation

## Overview

The `AuthService` handles Nakama authentication for the multiplayer Tic-Tac-Toe game. It provides robust authentication with device ID, automatic session management, exponential backoff retry logic, and session expiration handling.

## Features

### ✅ Device ID Authentication
- Authenticates users with Nakama using a unique device ID
- Device ID is generated once and persisted across app restarts
- Platform-specific device ID generation (web, Android, iOS)

### ✅ Secure Session Storage
- Session tokens are stored securely in local storage using `shared_preferences`
- Sessions are automatically restored on app restart
- Expired sessions are automatically cleaned up

### ✅ Exponential Backoff Retry
- Implements exponential backoff on authentication failures
- Retry delays: 1s, 2s, 4s, 8s, max 30s
- Prevents overwhelming the server with rapid retry attempts
- Automatically retries until successful or max delay is reached

### ✅ Authentication Status Stream
- Provides a broadcast stream of authentication status changes
- UI can listen to status changes and update accordingly
- Status values: `unauthenticated`, `authenticating`, `authenticated`, `error`

### ✅ Session Expiration Handling
- Automatically monitors session expiration every 30 seconds
- Attempts automatic re-authentication when session expires
- Notifies listeners of authentication status changes

### ✅ Re-authentication Support
- Handles session expiration gracefully
- Automatically re-authenticates when needed
- Maintains user experience during re-authentication

## Requirements Validation

This implementation validates the following requirements:

- **Requirement 1.1**: ✅ Authenticates player with Game_Server when client opens
- **Requirement 1.2**: ✅ Creates session for Player on successful authentication
- **Requirement 1.3**: ✅ Displays error message and retries on authentication failure
- **Requirement 1.4**: ✅ Maintains Player connection state while session is active
- **Requirement 15.1**: ✅ Implements error handling with exponential backoff retry

## API Reference

### Constructor

```dart
AuthService(NakamaBaseClient client)
```

Creates a new AuthService instance with the provided Nakama client.

### Properties

#### `status` (AuthStatus)
Returns the current authentication status.

```dart
AuthStatus get status
```

#### `session` (Session?)
Returns the current session, or null if not authenticated.

```dart
Session? get session
```

#### `statusStream` (Stream<AuthStatus>)
A broadcast stream that emits authentication status changes.

```dart
Stream<AuthStatus> get statusStream
```

#### `isAuthenticated` (bool)
Returns true if currently authenticated with a valid session.

```dart
bool get isAuthenticated
```

### Methods

#### `authenticate()`
Authenticates with Nakama using device ID. Implements exponential backoff retry on failure.

```dart
Future<Session> authenticate()
```

**Returns**: A `Future<Session>` that completes with the authenticated session.

**Throws**: `Exception` if authentication fails after all retry attempts.

**Example**:
```dart
try {
  final session = await authService.authenticate();
  print('Authenticated! User ID: ${session.userId}');
} catch (e) {
  print('Authentication failed: $e');
}
```

#### `reAuthenticate()`
Re-authenticates when the session expires. Clears the current session and calls `authenticate()`.

```dart
Future<void> reAuthenticate()
```

**Example**:
```dart
await authService.reAuthenticate();
```

#### `dispose()`
Disposes resources including timers and stream controllers. Call this when the AuthService is no longer needed.

```dart
void dispose()
```

**Example**:
```dart
@override
void dispose() {
  authService.dispose();
  super.dispose();
}
```

## Usage Examples

### Basic Usage

```dart
import 'package:frontend/services/auth_service.dart';
import 'package:nakama/nakama.dart';

// Create Nakama client
final client = getNakamaClient(
  host: 'localhost',
  ssl: false,
  serverKey: 'defaultkey',
);

// Create AuthService
final authService = AuthService(client);

// Authenticate
final session = await authService.authenticate();
print('Authenticated! User ID: ${session.userId}');
```

### Listening to Status Changes

```dart
authService.statusStream.listen((status) {
  switch (status) {
    case AuthStatus.unauthenticated:
      print('Not authenticated');
      break;
    case AuthStatus.authenticating:
      print('Authenticating...');
      break;
    case AuthStatus.authenticated:
      print('Authenticated!');
      break;
    case AuthStatus.error:
      print('Authentication error');
      break;
  }
});
```

### Using in a Flutter Widget

```dart
class AuthWidget extends StatefulWidget {
  @override
  _AuthWidgetState createState() => _AuthWidgetState();
}

class _AuthWidgetState extends State<AuthWidget> {
  late AuthService _authService;
  AuthStatus _status = AuthStatus.unauthenticated;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final client = getNakamaClient(
      host: 'your-server.com',
      ssl: true,
      serverKey: 'your-key',
    );
    
    _authService = AuthService(client);
    
    _authService.statusStream.listen((status) {
      setState(() => _status = status);
    });
    
    await _authService.authenticate();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == AuthStatus.authenticating) {
      return CircularProgressIndicator();
    }
    
    if (_status == AuthStatus.authenticated) {
      return Text('Welcome!');
    }
    
    return Text('Please wait...');
  }
}
```

## Error Handling

The AuthService implements robust error handling:

1. **Connection Errors**: Automatically retries with exponential backoff
2. **Session Expiration**: Automatically re-authenticates
3. **Storage Errors**: Gracefully handles storage failures and continues
4. **Invalid Sessions**: Cleans up expired sessions and re-authenticates

## Testing

Unit tests are provided in `frontend/test/auth_service_test.dart`.

Run tests with:
```bash
flutter test test/auth_service_test.dart
```

## Implementation Details

### Device ID Generation
- Web: `web_{timestamp}_{random}`
- Android: `android_{timestamp}_{random}`
- iOS: `ios_{timestamp}_{random}`
- Other: `unknown_{timestamp}_{random}`

### Session Storage
- Key: `nakama_session_token`
- Storage: `shared_preferences` (secure local storage)
- Automatic cleanup of expired sessions

### Session Monitoring
- Check interval: 30 seconds
- Automatic re-authentication on expiration
- Status updates via stream

### Retry Logic
- Delays: [1s, 2s, 4s, 8s, 30s]
- Max delay: 30 seconds (continues retrying at 30s intervals)
- Resets on successful authentication

## Security Considerations

1. **Session Tokens**: Stored securely in local storage
2. **Device ID**: Unique per device, persisted across app restarts
3. **No Sensitive Data**: Device ID contains no personal information
4. **Automatic Cleanup**: Expired sessions are removed from storage

## Future Enhancements

Potential improvements for future versions:

- [ ] Support for custom authentication (email/password)
- [ ] Support for social authentication (Google, Facebook)
- [ ] Biometric authentication support
- [ ] Session refresh token support
- [ ] Configurable retry delays
- [ ] Network connectivity detection before retry
- [ ] Offline mode support

## Troubleshooting

### Authentication Fails Immediately
- Check Nakama server is running and accessible
- Verify server URL and port are correct
- Check network connectivity

### Session Expires Too Quickly
- Check Nakama server session expiry configuration
- Verify system clock is correct
- Check for network issues causing delayed responses

### Device ID Not Persisting
- Check `shared_preferences` permissions
- Verify storage is not being cleared by the system
- Check for app data clearing in device settings

## Related Files

- `frontend/lib/services/auth_service.dart` - Main implementation
- `frontend/test/auth_service_test.dart` - Unit tests
- `frontend/lib/services/auth_service_example.dart` - Usage examples
- `.kiro/specs/multiplayer-tictactoe-nakama/requirements.md` - Requirements
- `.kiro/specs/multiplayer-tictactoe-nakama/design.md` - Design document
