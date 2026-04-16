// Example usage of AuthService
// This file demonstrates how to use the AuthService in your Flutter app

import 'package:frontend/services/auth_service.dart';
import 'package:nakama/nakama.dart';

/// Example: Initialize and use AuthService
Future<void> exampleAuthServiceUsage() async {
  // 1. Create Nakama client
  final client = getNakamaClient(
    host: 'localhost', // Replace with your Nakama server host
    ssl: false, // Set to true for production with HTTPS
    serverKey: 'defaultkey', // Replace with your server key
    httpPort: 7350,
  );

  // 2. Create AuthService
  final authService = AuthService(client);

  // 3. Listen to authentication status changes
  authService.statusStream.listen((status) {
    switch (status) {
      case AuthStatus.unauthenticated:
        print('User is not authenticated');
        break;
      case AuthStatus.authenticating:
        print('Authenticating...');
        break;
      case AuthStatus.authenticated:
        print('User authenticated successfully!');
        print('Session token: ${authService.session?.token}');
        break;
      case AuthStatus.error:
        print('Authentication error occurred');
        break;
    }
  });

  // 4. Authenticate
  try {
    final session = await authService.authenticate();
    print('Authentication successful!');
    print('User ID: ${session.userId}');
    print('Username: ${session.username}');
    print('Session expires at: ${session.expireTime}');
  } catch (e) {
    print('Authentication failed: $e');
  }

  // 5. Check authentication status
  if (authService.isAuthenticated) {
    print('User is currently authenticated');
    
    // Use the session for Nakama operations
    final session = authService.session!;
    // ... perform Nakama operations with session
  }

  // 6. Handle session expiration
  // The AuthService automatically monitors session expiration
  // and will attempt to re-authenticate when the session expires
  
  // 7. Clean up when done
  authService.dispose();
}

/// Example: Using AuthService in a Flutter widget
/// 
/// ```dart
/// class MyApp extends StatefulWidget {
///   @override
///   _MyAppState createState() => _MyAppState();
/// }
/// 
/// class _MyAppState extends State<MyApp> {
///   late AuthService _authService;
///   AuthStatus _authStatus = AuthStatus.unauthenticated;
/// 
///   @override
///   void initState() {
///     super.initState();
///     _initAuth();
///   }
/// 
///   Future<void> _initAuth() async {
///     final client = getNakamaClient(
///       host: 'your-server.com',
///       ssl: true,
///       serverKey: 'your-server-key',
///     );
///     
///     _authService = AuthService(client);
///     
///     _authService.statusStream.listen((status) {
///       setState(() {
///         _authStatus = status;
///       });
///     });
///     
///     await _authService.authenticate();
///   }
/// 
///   @override
///   void dispose() {
///     _authService.dispose();
///     super.dispose();
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         body: Center(
///           child: _buildAuthStatusWidget(),
///         ),
///       ),
///     );
///   }
/// 
///   Widget _buildAuthStatusWidget() {
///     switch (_authStatus) {
///       case AuthStatus.authenticating:
///         return CircularProgressIndicator();
///       case AuthStatus.authenticated:
///         return Text('Authenticated!');
///       case AuthStatus.error:
///         return Text('Authentication Error');
///       default:
///         return Text('Not Authenticated');
///     }
///   }
/// }
/// ```
