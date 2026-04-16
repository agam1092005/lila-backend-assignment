import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';
import 'package:frontend/services/theme_manager.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/screens/main_menu_screen.dart';
import 'package:frontend/screens/matchmaking_screen.dart';
import 'package:frontend/screens/game_screen.dart';
import 'package:frontend/screens/leaderboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize theme manager and load saved theme
  final themeManager = ThemeManager();
  await themeManager.loadTheme();
  
  // Get Nakama server URL from environment variable or use default
  const nakamaServerUrl = String.fromEnvironment(
    'NAKAMA_SERVER_URL',
    defaultValue: '152.67.10.16',
  );
  const nakamaPort = int.fromEnvironment('NAKAMA_PORT', defaultValue: 7350);
  const nakamaSsl = bool.fromEnvironment('NAKAMA_SSL', defaultValue: false);
  
  // Initialize Nakama client
  // Note: nakama package 1.3.0 uses host:port format
  final nakamaClient = getNakamaClient(
    host: '$nakamaServerUrl:$nakamaPort',
    ssl: nakamaSsl,
  );
  
  // Initialize auth service
  final authService = AuthService(nakamaClient);
  
  runApp(MyApp(
    themeManager: themeManager,
    authService: authService,
    nakamaClient: nakamaClient,
  ));
}

class MyApp extends StatefulWidget {
  final ThemeManager themeManager;
  final AuthService authService;
  final NakamaBaseClient nakamaClient;

  const MyApp({
    super.key,
    required this.themeManager,
    required this.authService,
    required this.nakamaClient,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticating = true;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      await widget.authService.authenticate();
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _authError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeManager,
      builder: (context, child) {
        return MaterialApp(
          title: 'Tic-Tac-Toe',
          theme: widget.themeManager.currentTheme,
          routes: {
            '/': (context) => _buildHome(),
            '/matchmaking': (context) => MatchmakingScreen(
                  authService: widget.authService,
                  nakamaClient: widget.nakamaClient,
                  themeManager: widget.themeManager,
                ),
            '/game': (context) => GameScreen(
                  authService: widget.authService,
                  nakamaClient: widget.nakamaClient,
                  themeManager: widget.themeManager,
                ),
            '/leaderboard': (context) => LeaderboardScreen(
                  nakamaClient: widget.nakamaClient,
                  themeManager: widget.themeManager,
                ),
          },
        );
      },
    );
  }

  Widget _buildHome() {
    if (_isAuthenticating) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Connecting to server...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_authError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Authentication Failed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _authError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isAuthenticating = true;
                      _authError = null;
                    });
                    _authenticate();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MainMenuScreen(
      themeManager: widget.themeManager,
      authService: widget.authService,
      nakamaClient: widget.nakamaClient,
    );
  }

  @override
  void dispose() {
    widget.authService.dispose();
    super.dispose();
  }
}
