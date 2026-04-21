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
  
  try {
    print('[MAIN] Starting app initialization...');
    
    // Initialize theme manager and load saved theme
    final themeManager = ThemeManager();
    await themeManager.loadTheme();
    print('[MAIN] Theme manager initialized');
    
    runApp(MyApp(
      themeManager: themeManager,
    ));
  } catch (e) {
    print('[MAIN] FATAL ERROR: $e');
    print('[MAIN] Stack trace: ${StackTrace.current}');
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  final ThemeManager themeManager;

  const MyApp({
    super.key,
    required this.themeManager,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthService _authService;
  late NakamaBaseClient _nakamaClient;
  bool _initialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeNakama();
  }

  Future<void> _initializeNakama() async {
    try {
      print('[APP] Initializing Nakama...');
      
      // Use empty host to make requests to the same server (nginx will proxy /v2/* to Nakama)
      const nakamaServerUrl = '';
      const nakamaSsl = false;
      const nakamaHttpPort = 80; // Use default port since we're on same origin
      // Server key is configured on Nakama server side
      const nakamaServerKey = 'defaultkey';
      
      print('[APP] Nakama config - Using same-origin requests (nginx proxy)');
      
      _nakamaClient = getNakamaClient(
        host: nakamaServerUrl,
        httpPort: nakamaHttpPort,
        ssl: nakamaSsl,
        serverKey: nakamaServerKey,
      );
      print('[APP] Nakama client created successfully');
      
      // Initialize auth service
      _authService = AuthService(_nakamaClient);
      print('[APP] Auth service initialized');
      
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('[APP] Error initializing Nakama: $e');
      print('[APP] Stack trace: $e');
      if (mounted) {
        setState(() {
          _initialized = true;
          _initError = e.toString();
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
          home: _buildHome(),
          routes: _initialized && _initError == null ? {
            '/matchmaking': (context) => MatchmakingScreen(
                  authService: _authService,
                  nakamaClient: _nakamaClient,
                  themeManager: widget.themeManager,
                ),
            '/game': (context) => GameScreen(
                  authService: _authService,
                  nakamaClient: _nakamaClient,
                  themeManager: widget.themeManager,
                ),
            '/leaderboard': (context) => LeaderboardScreen(
                  nakamaClient: _nakamaClient,
                  themeManager: widget.themeManager,
                ),
          } : {},
        );
      },
    );
  }

  Widget _buildHome() {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
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
                  'Initialization Failed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initialized = false;
                      _initError = null;
                    });
                    _initializeNakama();
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
      authService: _authService,
      nakamaClient: _nakamaClient,
    );
  }

  @override
  void dispose() {
    if (_initialized && _initError == null) {
      _authService.dispose();
    }
    super.dispose();
  }
}
