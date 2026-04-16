import 'dart:async';
import 'package:nakama/nakama.dart';

/// Game mode enum for matchmaking
enum GameMode {
  classic,
  timer;

  String toServerString() {
    return name; // "classic" or "timer"
  }
}

/// Matchmaking status enum
enum MatchmakingStatus {
  idle,
  searching,
  matchFound,
  timeout,
  cancelled,
  error,
}

/// Matchmaking error details
class MatchmakingError {
  final String message;
  final bool canRetry;
  final MatchmakingErrorType type;

  MatchmakingError({
    required this.message,
    this.canRetry = true,
    required this.type,
  });
}

/// Types of matchmaking errors
enum MatchmakingErrorType {
  connection,
  timeout,
  serverError,
  cancelled,
  unknown,
}

/// MatchmakingService handles matchmaking requests with Nakama
/// Implements timeout, cancellation, and status streaming
class MatchmakingService {
  final String _host;
  final int _port;
  final bool _ssl;
  
  Session? _session;
  NakamaWebsocketClient? _socket;
  
  final _statusController = StreamController<MatchmakingStatus>.broadcast();
  final _errorController = StreamController<MatchmakingError>.broadcast();
  MatchmakingStatus _currentStatus = MatchmakingStatus.idle;
  
  String? _currentTicket;
  Timer? _timeoutTimer;
  StreamSubscription<MatchmakerMatched>? _matchmakerSubscription;
  
  // Timeout configuration
  static const Duration _matchmakingTimeout = Duration(seconds: 60);
  
  // Completer for async match finding
  Completer<Match>? _matchCompleter;

  MatchmakingService({
    required String host,
    required int port,
    required bool ssl,
  })  : _host = host,
        _port = port,
        _ssl = ssl;

  /// Get current matchmaking status
  MatchmakingStatus get status => _currentStatus;

  /// Stream of matchmaking status changes
  Stream<MatchmakingStatus> get statusStream => _statusController.stream;

  /// Stream of matchmaking errors
  Stream<MatchmakingError> get errorStream => _errorController.stream;

  /// Check if currently searching for a match
  bool get isSearching => _currentStatus == MatchmakingStatus.searching;

  /// Find a match with the specified game mode
  /// Returns a Match object when a match is found
  /// Throws TimeoutException if matchmaking times out after 60 seconds
  /// Throws Exception if matchmaking is cancelled or encounters an error
  Future<Match> findMatch({
    required Session session,
    required GameMode gameMode,
  }) async {
    // Prevent multiple simultaneous matchmaking requests
    if (isSearching) {
      final error = MatchmakingError(
        message: 'Already searching for a match. Please wait or cancel the current search.',
        canRetry: false,
        type: MatchmakingErrorType.unknown,
      );
      _errorController.add(error);
      throw Exception(error.message);
    }

    _session = session;
    _updateStatus(MatchmakingStatus.searching);
    _matchCompleter = Completer<Match>();

    try {
      // Create socket connection with session token
      _socket = NakamaWebsocketClient.init(
        host: _host,
        port: _port,
        ssl: _ssl,
        token: session.token,
      );

      // Listen for matchmaker matched events
      _matchmakerSubscription = _socket!.onMatchmakerMatched.listen(
        _handleMatchFound,
        onError: _handleMatchmakingError,
      );

      // Add player to matchmaking queue with game mode property
      final ticket = await _socket!.addMatchmaker(
        minCount: 2,
        maxCount: 2,
        query: '+properties.game_mode:${gameMode.toServerString()}',
        stringProperties: {
          'game_mode': gameMode.toServerString(),
        },
      );

      _currentTicket = ticket.ticket;

      // Start timeout timer
      _startTimeoutTimer();

      // Wait for match to be found or timeout/cancellation
      return await _matchCompleter!.future;
    } on TimeoutException catch (e) {
      _updateStatus(MatchmakingStatus.timeout);
      final error = MatchmakingError(
        message: 'Matchmaking timed out after 60 seconds. No opponent found. Please try again.',
        canRetry: true,
        type: MatchmakingErrorType.timeout,
      );
      _errorController.add(error);
      _cleanup();
      rethrow;
    } catch (e) {
      _updateStatus(MatchmakingStatus.error);
      
      // Determine error type and message
      String errorMessage;
      MatchmakingErrorType errorType;
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException') ||
          e.toString().contains('Connection')) {
        errorMessage = 'Cannot connect to matchmaking server. Please check your internet connection.';
        errorType = MatchmakingErrorType.connection;
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Matchmaking was cancelled.';
        errorType = MatchmakingErrorType.cancelled;
      } else {
        errorMessage = 'Matchmaking failed: ${e.toString()}';
        errorType = MatchmakingErrorType.serverError;
      }
      
      final error = MatchmakingError(
        message: errorMessage,
        canRetry: errorType != MatchmakingErrorType.cancelled,
        type: errorType,
      );
      _errorController.add(error);
      _cleanup();
      rethrow;
    }
  }

  /// Cancel the current matchmaking request
  Future<void> cancelMatchmaking() async {
    if (!isSearching || _currentTicket == null || _socket == null) {
      return;
    }

    try {
      await _socket!.removeMatchmaker(_currentTicket!);
      
      _updateStatus(MatchmakingStatus.cancelled);
      
      if (_matchCompleter != null && !_matchCompleter!.isCompleted) {
        _matchCompleter!.completeError(
          Exception('Matchmaking cancelled by user'),
        );
      }
    } catch (e) {
      // Log error but don't throw - cancellation should always succeed from user perspective
      print('Warning: Error during matchmaking cancellation: $e');
    } finally {
      _cleanup();
    }
  }

  /// Handle match found event from Nakama
  Future<void> _handleMatchFound(MatchmakerMatched matchmakerMatched) async {
    _updateStatus(MatchmakingStatus.matchFound);
    _timeoutTimer?.cancel();

    try {
      // Join the match
      final matchId = matchmakerMatched.matchId ?? '';
      if (matchId.isEmpty) {
        throw Exception('Match ID is empty');
      }

      final match = await _socket!.joinMatch(matchId);
      
      if (_matchCompleter != null && !_matchCompleter!.isCompleted) {
        _matchCompleter!.complete(match);
      }
    } catch (e) {
      _updateStatus(MatchmakingStatus.error);
      
      final error = MatchmakingError(
        message: 'Failed to join match: ${e.toString()}',
        canRetry: true,
        type: MatchmakingErrorType.serverError,
      );
      _errorController.add(error);
      
      if (_matchCompleter != null && !_matchCompleter!.isCompleted) {
        _matchCompleter!.completeError(Exception(error.message));
      }
    } finally {
      _cleanup();
    }
  }

  /// Handle matchmaking error
  void _handleMatchmakingError(dynamic error) {
    _updateStatus(MatchmakingStatus.error);
    
    final matchmakingError = MatchmakingError(
      message: 'Matchmaking error: ${error.toString()}',
      canRetry: true,
      type: MatchmakingErrorType.serverError,
    );
    _errorController.add(matchmakingError);
    
    if (_matchCompleter != null && !_matchCompleter!.isCompleted) {
      _matchCompleter!.completeError(Exception(matchmakingError.message));
    }
    
    _cleanup();
  }

  /// Start timeout timer for matchmaking
  void _startTimeoutTimer() {
    _timeoutTimer = Timer(_matchmakingTimeout, () async {
      _updateStatus(MatchmakingStatus.timeout);
      
      // Remove from matchmaker on timeout
      if (_currentTicket != null && _socket != null) {
        try {
          await _socket!.removeMatchmaker(_currentTicket!);
        } catch (e) {
          // Log error but don't throw - timeout should always complete
          print('Warning: Error removing matchmaker on timeout: $e');
        }
      }
      
      final error = MatchmakingError(
        message: 'Matchmaking timed out after 60 seconds. No opponent found. Please try again.',
        canRetry: true,
        type: MatchmakingErrorType.timeout,
      );
      _errorController.add(error);
      
      if (_matchCompleter != null && !_matchCompleter!.isCompleted) {
        _matchCompleter!.completeError(
          TimeoutException('Matchmaking timed out after 60 seconds'),
        );
      }
      
      _cleanup();
    });
  }

  /// Update matchmaking status and notify listeners
  void _updateStatus(MatchmakingStatus newStatus) {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  /// Clean up resources after matchmaking completes, times out, or is cancelled
  void _cleanup() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    
    _matchmakerSubscription?.cancel();
    _matchmakerSubscription = null;
    
    _socket?.close();
    _socket = null;
    
    _currentTicket = null;
    _matchCompleter = null;
  }

  /// Dispose resources
  void dispose() {
    _cleanup();
    _statusController.close();
    _errorController.close();
  }
}
