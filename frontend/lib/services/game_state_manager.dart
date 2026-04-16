import 'dart:async';
import 'dart:convert';
import 'package:nakama/nakama.dart';
import '../models/game_state.dart';

/// Connection status enum
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// GameStateManager handles real-time game state updates from Nakama match
/// Listens for state updates, disconnections, and outcomes via WebSocket
class GameStateManager {
  final String _host;
  final int _port;
  final bool _ssl;

  NakamaWebsocketClient? _socket;
  Match? _currentMatch;
  Session? _session;

  final _gameStateController = StreamController<GameState>.broadcast();
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _playerDisconnectedController = StreamController<String>.broadcast();

  ConnectionStatus _currentConnectionStatus = ConnectionStatus.disconnected;
  GameState? _latestGameState;

  StreamSubscription<MatchData>? _matchDataSubscription;
  StreamSubscription<MatchPresenceEvent>? _matchPresenceSubscription;

  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const List<int> _reconnectionDelays = [1, 2, 4, 8, 16]; // seconds

  GameStateManager({
    required String host,
    required int port,
    required bool ssl,
  })  : _host = host,
        _port = port,
        _ssl = ssl;

  /// Get current connection status
  ConnectionStatus get connectionStatus => _currentConnectionStatus;

  /// Get latest game state
  GameState? get latestGameState => _latestGameState;

  /// Stream of game state updates
  Stream<GameState> get gameStateStream => _gameStateController.stream;

  /// Stream of connection status changes
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  /// Stream of error messages
  Stream<String> get errorStream => _errorController.stream;

  /// Stream of player disconnection events (contains disconnected player ID)
  Stream<String> get playerDisconnectedStream =>
      _playerDisconnectedController.stream;

  /// Check if currently connected to a match
  bool get isConnected => _currentConnectionStatus == ConnectionStatus.connected;

  /// Connect to a Nakama match and start listening for updates
  Future<void> connectToMatch({
    required Session session,
    required Match match,
  }) async {
    // Disconnect from any existing match first
    await disconnect();

    _session = session;
    _currentMatch = match;
    _updateConnectionStatus(ConnectionStatus.connecting);

    try {
      // Create WebSocket connection
      _socket = NakamaWebsocketClient.init(
        host: _host,
        port: _port,
        ssl: _ssl,
        token: session.token,
      );

      // Listen for match data (game state updates, errors, etc.)
      _matchDataSubscription = _socket!.onMatchData.listen(
        _handleMatchData,
        onError: _handleConnectionError,
        onDone: _handleConnectionClosed,
      );

      // Listen for match presence events (player joins/leaves)
      _matchPresenceSubscription = _socket!.onMatchPresence.listen(
        _handleMatchPresence,
        onError: _handleConnectionError,
      );

      _updateConnectionStatus(ConnectionStatus.connected);
      _reconnectionAttempts = 0; // Reset reconnection counter on success
    } catch (e) {
      _updateConnectionStatus(ConnectionStatus.error);
      
      // Determine error message
      String errorMessage;
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException') ||
          e.toString().contains('Connection')) {
        errorMessage = 'Cannot connect to game server. Please check your internet connection.';
      } else {
        errorMessage = 'Failed to connect to match: ${e.toString()}';
      }
      
      _errorController.add(errorMessage);
      
      // Attempt reconnection
      _attemptReconnection();
    }
  }

  /// Handle incoming match data messages
  void _handleMatchData(MatchData data) {
    try {
      // Decode the message data
      final dataBytes = data.data ?? [];
      if (dataBytes.isEmpty) {
        print('Warning: Received empty match data');
        return;
      }
      
      final messageJson = jsonDecode(utf8.decode(dataBytes));
      final messageType = messageJson['type'] as String?;

      if (messageType == null) {
        print('Warning: Message type is null');
        return;
      }

      switch (messageType) {
        case 'state_update':
          _handleStateUpdate(messageJson);
          break;
        case 'player_disconnected':
          _handlePlayerDisconnected(messageJson);
          break;
        case 'move_rejected':
          _handleMoveRejected(messageJson);
          break;
        case 'error':
          _handleErrorMessage(messageJson);
          break;
        default:
          // Unknown message type, log but don't crash
          print('Unknown message type: $messageType');
      }
    } catch (e) {
      _errorController.add('Failed to parse match data: ${e.toString()}');
    }
  }

  /// Handle game state update message
  void _handleStateUpdate(Map<String, dynamic> json) {
    try {
      final gameState = GameState.fromJson(json);
      _latestGameState = gameState;
      _gameStateController.add(gameState);
    } catch (e) {
      _errorController.add('Failed to parse game state: $e');
    }
  }

  /// Handle player disconnected message
  void _handlePlayerDisconnected(Map<String, dynamic> json) {
    final playerId = json['playerId'] as String?;
    if (playerId != null) {
      _playerDisconnectedController.add(playerId);
    }
  }

  /// Handle move rejected message
  void _handleMoveRejected(Map<String, dynamic> json) {
    final reason = json['reason'] as String? ?? 'Move rejected';
    _errorController.add(reason);
  }

  /// Handle error message from server
  void _handleErrorMessage(Map<String, dynamic> json) {
    final message = json['message'] as String? ?? 'Unknown error';
    _errorController.add(message);
  }

  /// Handle match presence events (player joins/leaves)
  void _handleMatchPresence(MatchPresenceEvent event) {
    // Handle player leaves
    for (final leave in event.leaves) {
      // Notify about disconnection
      _playerDisconnectedController.add(leave.userId);
    }

    // Note: Player joins are handled by the server sending state updates
  }

  /// Handle connection error
  void _handleConnectionError(dynamic error) {
    _updateConnectionStatus(ConnectionStatus.error);
    
    // Determine error message
    String errorMessage;
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkException') ||
        error.toString().contains('Connection')) {
      errorMessage = 'Connection lost. Attempting to reconnect...';
    } else {
      errorMessage = 'Connection error: ${error.toString()}';
    }
    
    _errorController.add(errorMessage);
    
    // Attempt reconnection
    _attemptReconnection();
  }

  /// Handle connection closed
  void _handleConnectionClosed() {
    if (_currentConnectionStatus == ConnectionStatus.connected ||
        _currentConnectionStatus == ConnectionStatus.reconnecting) {
      _updateConnectionStatus(ConnectionStatus.disconnected);
      _errorController.add('Connection closed. Attempting to reconnect...');
      
      // Attempt reconnection
      _attemptReconnection();
    }
  }

  /// Attempt to reconnect to the match
  void _attemptReconnection() {
    // Don't attempt reconnection if we're already reconnecting or have no match
    if (_currentConnectionStatus == ConnectionStatus.reconnecting ||
        _currentMatch == null ||
        _session == null) {
      return;
    }

    // Check if we've exceeded max reconnection attempts
    if (_reconnectionAttempts >= _maxReconnectionAttempts) {
      _updateConnectionStatus(ConnectionStatus.error);
      _errorController.add(
        'Failed to reconnect after $_maxReconnectionAttempts attempts. '
        'Please return to the main menu and try again.'
      );
      return;
    }

    _updateConnectionStatus(ConnectionStatus.reconnecting);

    // Get delay for this attempt
    final delayIndex = _reconnectionAttempts.clamp(0, _reconnectionDelays.length - 1);
    final delay = _reconnectionDelays[delayIndex];
    _reconnectionAttempts++;

    _errorController.add(
      'Reconnecting... (Attempt $_reconnectionAttempts/$_maxReconnectionAttempts, '
      'waiting ${delay}s)'
    );

    // Schedule reconnection attempt
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(Duration(seconds: delay), () async {
      try {
        await connectToMatch(
          session: _session!,
          match: _currentMatch!,
        );
      } catch (e) {
        // connectToMatch will handle the error and trigger another reconnection attempt
        print('Reconnection attempt $_reconnectionAttempts failed: $e');
      }
    });
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(ConnectionStatus newStatus) {
    _currentConnectionStatus = newStatus;
    _connectionStatusController.add(newStatus);
  }

  /// Disconnect from the current match
  Future<void> disconnect() async {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;

    _matchDataSubscription?.cancel();
    _matchDataSubscription = null;

    _matchPresenceSubscription?.cancel();
    _matchPresenceSubscription = null;

    if (_socket != null) {
      try {
        // Leave the match if we're in one
        if (_currentMatch != null) {
          await _socket!.leaveMatch(_currentMatch!.matchId);
        }
        _socket!.close();
      } catch (e) {
        // Log error but don't throw - disconnect should always succeed
        print('Warning: Error during disconnect: $e');
      }
      _socket = null;
    }

    _currentMatch = null;
    _session = null;
    _latestGameState = null;
    _reconnectionAttempts = 0;

    _updateConnectionStatus(ConnectionStatus.disconnected);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _gameStateController.close();
    _connectionStatusController.close();
    _errorController.close();
    _playerDisconnectedController.close();
  }
}
