// Example usage of MatchmakingService
// This file demonstrates how to use the MatchmakingService in your Flutter app

import 'package:frontend/services/matchmaking_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:nakama/nakama.dart';

/// Example: Initialize and use MatchmakingService
Future<void> exampleMatchmakingServiceUsage() async {
  // 1. First, authenticate with Nakama (prerequisite)
  final client = getNakamaClient(
    host: 'localhost',
    ssl: false,
    serverKey: 'defaultkey',
    httpPort: 7350,
  );

  final authService = AuthService(client);
  final session = await authService.authenticate();

  // 2. Create MatchmakingService
  final matchmakingService = MatchmakingService(
    host: 'localhost',
    port: 7350, // WebSocket port
    ssl: false,
  );

  // 3. Listen to matchmaking status changes
  matchmakingService.statusStream.listen((status) {
    switch (status) {
      case MatchmakingStatus.idle:
        print('Matchmaking is idle');
        break;
      case MatchmakingStatus.searching:
        print('Searching for opponent...');
        break;
      case MatchmakingStatus.matchFound:
        print('Match found! Joining...');
        break;
      case MatchmakingStatus.timeout:
        print('Matchmaking timed out after 60 seconds');
        break;
      case MatchmakingStatus.cancelled:
        print('Matchmaking cancelled by user');
        break;
      case MatchmakingStatus.error:
        print('Matchmaking error occurred');
        break;
    }
  });

  // 4. Find a match with classic mode
  try {
    final match = await matchmakingService.findMatch(
      session: session,
      gameMode: GameMode.classic,
    );
    
    print('Successfully joined match!');
    print('Match ID: ${match.matchId}');
    print('Self: ${match.self}');
    print('Presences: ${match.presences}');
    
    // Now you can use the match object to send/receive game messages
  } on TimeoutException catch (e) {
    print('Matchmaking timed out: $e');
  } catch (e) {
    print('Matchmaking failed: $e');
  }

  // 5. Find a match with timer mode
  try {
    final match = await matchmakingService.findMatch(
      session: session,
      gameMode: GameMode.timer,
    );
    
    print('Successfully joined timer mode match!');
  } catch (e) {
    print('Matchmaking failed: $e');
  }

  // 6. Cancel matchmaking (if needed)
  // This can be called while matchmaking is in progress
  await matchmakingService.cancelMatchmaking();

  // 7. Clean up when done
  matchmakingService.dispose();
  authService.dispose();
}

/// Example: Using MatchmakingService in a Flutter widget
/// 
/// ```dart
/// class MatchmakingScreen extends StatefulWidget {
///   final Session session;
///   
///   const MatchmakingScreen({required this.session});
/// 
///   @override
///   _MatchmakingScreenState createState() => _MatchmakingScreenState();
/// }
/// 
/// class _MatchmakingScreenState extends State<MatchmakingScreen> {
///   late MatchmakingService _matchmakingService;
///   MatchmakingStatus _status = MatchmakingStatus.idle;
///   GameMode _selectedMode = GameMode.classic;
/// 
///   @override
///   void initState() {
///     super.initState();
///     
///     _matchmakingService = MatchmakingService(
///       host: 'your-server.com',
///       port: 7350,
///       ssl: true,
///     );
///     
///     _matchmakingService.statusStream.listen((status) {
///       setState(() {
///         _status = status;
///       });
///       
///       // Handle status changes
///       if (status == MatchmakingStatus.timeout) {
///         _showTimeoutDialog();
///       }
///     });
///   }
/// 
///   @override
///   void dispose() {
///     _matchmakingService.dispose();
///     super.dispose();
///   }
/// 
///   Future<void> _startMatchmaking() async {
///     try {
///       final match = await _matchmakingService.findMatch(
///         session: widget.session,
///         gameMode: _selectedMode,
///       );
///       
///       // Navigate to game screen
///       Navigator.push(
///         context,
///         MaterialPageRoute(
///           builder: (context) => GameScreen(match: match),
///         ),
///       );
///     } catch (e) {
///       _showErrorDialog(e.toString());
///     }
///   }
/// 
///   Future<void> _cancelMatchmaking() async {
///     await _matchmakingService.cancelMatchmaking();
///   }
/// 
///   void _showTimeoutDialog() {
///     showDialog(
///       context: context,
///       builder: (context) => AlertDialog(
///         title: Text('Matchmaking Timeout'),
///         content: Text('Could not find an opponent. Please try again.'),
///         actions: [
///           TextButton(
///             onPressed: () => Navigator.pop(context),
///             child: Text('OK'),
///           ),
///         ],
///       ),
///     );
///   }
/// 
///   void _showErrorDialog(String error) {
///     showDialog(
///       context: context,
///       builder: (context) => AlertDialog(
///         title: Text('Matchmaking Error'),
///         content: Text(error),
///         actions: [
///           TextButton(
///             onPressed: () => Navigator.pop(context),
///             child: Text('OK'),
///           ),
///         ],
///       ),
///     );
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Find Match')),
///       body: Center(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: [
///             // Game mode selection
///             SegmentedButton<GameMode>(
///               segments: [
///                 ButtonSegment(
///                   value: GameMode.classic,
///                   label: Text('Classic'),
///                 ),
///                 ButtonSegment(
///                   value: GameMode.timer,
///                   label: Text('Timer'),
///                 ),
///               ],
///               selected: {_selectedMode},
///               onSelectionChanged: (Set<GameMode> newSelection) {
///                 setState(() {
///                   _selectedMode = newSelection.first;
///                 });
///               },
///             ),
///             
///             SizedBox(height: 32),
///             
///             // Status display
///             if (_status == MatchmakingStatus.searching)
///               Column(
///                 children: [
///                   CircularProgressIndicator(),
///                   SizedBox(height: 16),
///                   Text('Searching for opponent...'),
///                   SizedBox(height: 16),
///                   ElevatedButton(
///                     onPressed: _cancelMatchmaking,
///                     child: Text('Cancel'),
///                   ),
///                 ],
///               )
///             else
///               ElevatedButton(
///                 onPressed: _startMatchmaking,
///                 child: Text('Find Match'),
///               ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```

/// Example: Handling matchmaking timeout
/// 
/// The service automatically times out after 60 seconds if no match is found.
/// You can handle this by listening to the status stream:
/// 
/// ```dart
/// matchmakingService.statusStream.listen((status) {
///   if (status == MatchmakingStatus.timeout) {
///     // Show timeout notification to user
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(
///         content: Text('Could not find an opponent. Please try again.'),
///         action: SnackBarAction(
///           label: 'Retry',
///           onPressed: () {
///             // Retry matchmaking
///             _startMatchmaking();
///           },
///         ),
///       ),
///     );
///   }
/// });
/// ```

/// Example: Preventing multiple simultaneous matchmaking requests
/// 
/// The service prevents multiple simultaneous requests automatically:
/// 
/// ```dart
/// if (matchmakingService.isSearching) {
///   print('Already searching for a match');
///   return;
/// }
/// 
/// // Start matchmaking
/// await matchmakingService.findMatch(
///   session: session,
///   gameMode: GameMode.classic,
/// );
/// ```
