import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';
import 'package:frontend/services/matchmaking_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/theme_manager.dart';
import 'package:frontend/utils/responsive_helper.dart';

class MatchmakingScreen extends StatefulWidget {
  final AuthService authService;
  final NakamaBaseClient nakamaClient;
  final ThemeManager themeManager;

  const MatchmakingScreen({
    super.key,
    required this.authService,
    required this.nakamaClient,
    required this.themeManager,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  late MatchmakingService _matchmakingService;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Extract host, port, and SSL from Nakama client
    const nakamaServerUrl = String.fromEnvironment(
      'NAKAMA_SERVER_URL',
      defaultValue: 'localhost',
    );
    const nakamaPort = int.fromEnvironment('NAKAMA_PORT', defaultValue: 7350);
    const nakamaSsl = bool.fromEnvironment('NAKAMA_SSL', defaultValue: false);
    
    _matchmakingService = MatchmakingService(
      host: nakamaServerUrl,
      port: nakamaPort,
      ssl: nakamaSsl,
    );
    
    // Listen for matchmaking errors
    _matchmakingService.errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
        
        // Show error dialog
        _showErrorDialog(error.message, error.canRetry);
      }
    });
  }

  @override
  void dispose() {
    _matchmakingService.dispose();
    super.dispose();
  }

  Future<void> _startMatchmaking(GameMode gameMode) async {
    if (_isSearching) return;
    
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });
    
    try {
      final session = widget.authService.session;
      if (session == null) {
        throw Exception('Not authenticated');
      }
      
      final match = await _matchmakingService.findMatch(
        session: session,
        gameMode: gameMode,
      );
      
      if (mounted) {
        // Navigate to game screen with match data
        Navigator.pushReplacementNamed(
          context,
          '/game',
          arguments: {
            'match': match,
            'gameMode': gameMode,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _cancelMatchmaking() async {
    await _matchmakingService.cancelMatchmaking();
    
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showErrorDialog(String message, bool canRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Matchmaking Error'),
        content: Text(message),
        actions: [
          if (canRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Return to main menu
              },
              child: const Text('Return to Menu'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);
    final padding = ResponsiveHelper.getPadding(screenWidth);
    final buttonHeight = ResponsiveHelper.getButtonHeight(screenWidth);
    final spacing = ResponsiveHelper.getSpacing(screenWidth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchmaking'),
        automaticallyImplyLeading: !_isSearching,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : ResponsiveHelper.desktopMaxContentWidth,
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isSearching) ...[
                // Title
                Text(
                  'Select Game Mode',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 24 : 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing * 2),
                
                // Classic Mode Button
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () => _startMatchmaking(GameMode.classic),
                    icon: Icon(Icons.grid_on, size: isMobile ? 28 : 24),
                    label: Text(
                      'Classic Mode',
                      style: TextStyle(fontSize: isMobile ? 18 : 16),
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                
                // Timer Mode Button
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () => _startMatchmaking(GameMode.timer),
                    icon: Icon(Icons.timer, size: isMobile ? 28 : 24),
                    label: Text(
                      'Timer Mode',
                      style: TextStyle(fontSize: isMobile ? 18 : 16),
                    ),
                  ),
                ),
              ] else ...[
                // Searching indicator
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: spacing * 2),
                    Text(
                      'Searching for opponent...',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: isMobile ? 20 : 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing),
                    Text(
                      'This may take up to 60 seconds',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                        fontSize: isMobile ? 15 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: spacing * 3),
                
                // Cancel Button
                SizedBox(
                  height: buttonHeight * 0.8,
                  child: OutlinedButton(
                    onPressed: _cancelMatchmaking,
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: isMobile ? 16 : 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
