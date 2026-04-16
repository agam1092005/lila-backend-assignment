import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/theme_manager.dart';
import 'package:frontend/services/game_state_manager.dart';
import 'package:frontend/services/move_controller.dart';
import 'package:frontend/models/game_state.dart';
import 'package:frontend/widgets/game_board.dart';
import 'package:frontend/widgets/player_info_widget.dart';
import 'package:frontend/widgets/turn_indicator.dart';
import 'package:frontend/widgets/timer_display.dart';
import 'package:frontend/widgets/theme_toggle.dart';
import 'package:frontend/widgets/outcome_dialog.dart';
import 'package:frontend/utils/responsive_helper.dart';

class GameScreen extends StatefulWidget {
  final AuthService authService;
  final NakamaBaseClient nakamaClient;
  final ThemeManager themeManager;

  const GameScreen({
    super.key,
    required this.authService,
    required this.nakamaClient,
    required this.themeManager,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameStateManager _gameStateManager;
  MoveController? _moveController;
  GameState? _currentGameState;
  bool _isConnecting = true;
  String? _errorMessage;
  bool _hasShownOutcome = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Extract host, port, and SSL from environment
    const nakamaServerUrl = String.fromEnvironment(
      'NAKAMA_SERVER_URL',
      defaultValue: '152.67.10.16',
    );
    const nakamaPort = int.fromEnvironment('NAKAMA_PORT', defaultValue: 7350);
    const nakamaSsl = bool.fromEnvironment('NAKAMA_SSL', defaultValue: false);
    
    _gameStateManager = GameStateManager(
      host: nakamaServerUrl,
      port: nakamaPort,
      ssl: nakamaSsl,
    );
    
    // Listen for game state updates
    _gameStateManager.gameStateStream.listen((gameState) {
      if (mounted) {
        setState(() {
          _currentGameState = gameState;
        });
        
        // Show outcome dialog when game ends
        if (gameState.isGameOver && !_hasShownOutcome) {
          _hasShownOutcome = true;
          _showOutcomeDialog(gameState);
        }
        
        // Notify move controller of successful move
        _moveController?.handleMoveSuccess();
      }
    });
    
    // Listen for connection status changes
    _gameStateManager.connectionStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isConnecting = status == ConnectionStatus.connecting ||
                          status == ConnectionStatus.reconnecting;
        });
      }
    });
    
    // Listen for errors
    _gameStateManager.errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _errorMessage = error;
        });
        
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
    
    // Listen for player disconnections
    _gameStateManager.playerDisconnectedStream.listen((playerId) {
      if (mounted && _currentGameState != null && !_hasShownOutcome) {
        _hasShownOutcome = true;
        _showOutcomeDialog(_currentGameState!, isDisconnection: true);
      }
    });
    
    // Connect to match
    _connectToMatch();
  }

  Future<void> _connectToMatch() async {
    // Get match data from navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      _showError('No match data provided');
      return;
    }
    
    final match = args['match'] as Match?;
    final session = widget.authService.session;
    
    if (match == null || session == null) {
      _showError('Invalid match or session');
      return;
    }
    
    try {
      await _gameStateManager.connectToMatch(
        session: session,
        match: match,
      );
      
      // Initialize move controller after connection
      // We need to create a WebSocket client for the move controller
      final socket = NakamaWebsocketClient.init(
        host: const String.fromEnvironment('NAKAMA_SERVER_URL', defaultValue: '152.67.10.16'),
        port: const int.fromEnvironment('NAKAMA_PORT', defaultValue: 7350),
        ssl: const bool.fromEnvironment('NAKAMA_SSL', defaultValue: false),
        token: session.token,
      );
      
      _moveController = MoveController(
        socket: socket,
        matchId: match.matchId,
      );
      
      // Listen for move controller errors
      _moveController!.errorStream.listen((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
      
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    } catch (e) {
      _showError('Failed to connect to match: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isConnecting = false;
      });
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Connection Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _returnToMainMenu();
              },
              child: const Text('Return to Menu'),
            ),
          ],
        ),
      );
    }
  }

  void _showOutcomeDialog(GameState gameState, {bool isDisconnection = false}) {
    OutcomeDialog.show(
      context,
      outcome: gameState.outcome,
      player1Username: gameState.player1.username,
      player2Username: gameState.player2.username,
      isDisconnection: isDisconnection,
      onReturnToMenu: _returnToMainMenu,
    );
  }

  Future<void> _returnToMainMenu() async {
    await _gameStateManager.disconnect();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> _handleCellTap(int row, int col) async {
    if (_moveController == null || _currentGameState == null) return;
    
    // Check if it's the player's turn
    // This is a basic check - the server will do the authoritative validation
    await _moveController!.submitMove(row, col);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);
    final padding = ResponsiveHelper.getPadding(screenWidth);
    final spacing = ResponsiveHelper.getSpacing(screenWidth);

    if (_isConnecting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: spacing),
              Text(
                'Connecting to game...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_currentGameState == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: spacing),
              Text(
                'Waiting for game state...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        automaticallyImplyLeading: false,
        actions: [
          ThemeToggle(themeManager: widget.themeManager),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : ResponsiveHelper.desktopMaxContentWidth,
          ),
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Player Info Section
                PlayerInfoWidget(
                  player1: _currentGameState!.player1,
                  player2: _currentGameState!.player2,
                  currentTurn: _currentGameState!.currentTurn,
                ),
                SizedBox(height: spacing),
                
                // Turn Indicator
                Center(
                  child: TurnIndicator(
                    currentPlayer: _currentGameState!.currentPlayer,
                    isGameOver: _currentGameState!.isGameOver,
                  ),
                ),
                SizedBox(height: spacing),
                
                // Timer Display (for timer mode only)
                if (_currentGameState!.isTimerMode)
                  Center(
                    child: TimerDisplay(
                      timerRemaining: _currentGameState!.timerRemaining,
                      isTimerMode: _currentGameState!.isTimerMode,
                    ),
                  ),
                if (_currentGameState!.isTimerMode)
                  SizedBox(height: spacing),
                
                // Game Board
                Center(
                  child: GameBoard(
                    gameState: _currentGameState!,
                    onCellTap: _handleCellTap,
                  ),
                ),
                SizedBox(height: spacing * 2),
                
                // Return to Menu Button (only show when game is over)
                if (_currentGameState!.isGameOver)
                  SizedBox(
                    height: ResponsiveHelper.getButtonHeight(screenWidth) * 0.8,
                    child: OutlinedButton.icon(
                      onPressed: _returnToMainMenu,
                      icon: Icon(Icons.home, size: isMobile ? 24 : 20),
                      label: Text(
                        'Return to Menu',
                        style: TextStyle(fontSize: isMobile ? 16 : 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameStateManager.dispose();
    _moveController?.dispose();
    super.dispose();
  }
}
