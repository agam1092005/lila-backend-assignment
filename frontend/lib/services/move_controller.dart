import 'dart:async';
import 'dart:convert';
import 'package:nakama/nakama.dart';

/// MoveController handles player move input and submission to the server
/// Captures board cell tap events, sends move requests via Nakama match signal,
/// handles move rejection errors, and prevents multiple simultaneous submissions
class MoveController {
  final NakamaWebsocketClient _socket;
  final String _matchId;

  bool _isSubmitting = false;
  final _errorController = StreamController<String>.broadcast();

  MoveController({
    required NakamaWebsocketClient socket,
    required String matchId,
  })  : _socket = socket,
        _matchId = matchId;

  /// Check if a move is currently being submitted
  bool get isSubmitting => _isSubmitting;

  /// Stream of error messages (move rejections)
  Stream<String> get errorStream => _errorController.stream;

  /// Submit a move to the server
  /// Returns true if the move was sent successfully, false if submission is blocked
  /// Actual move validation happens on the server
  Future<bool> submitMove(int row, int col) async {
    // Prevent multiple simultaneous move submissions
    if (_isSubmitting) {
      _errorController.add('Please wait for the current move to complete');
      return false;
    }

    // Validate coordinates are in valid range (0-2)
    if (row < 0 || row > 2 || col < 0 || col > 2) {
      _errorController.add('Invalid move coordinates');
      return false;
    }

    _isSubmitting = true;

    try {
      // Create move request message
      final moveRequest = {
        'type': 'move',
        'row': row,
        'col': col,
      };

      // Encode message as JSON
      final messageJson = jsonEncode(moveRequest);
      final messageBytes = utf8.encode(messageJson);

      // Send move request to server via match signal
      // Op code 1 is used for game moves
      _socket.sendMatchData(
        matchId: _matchId,
        opCode: 1,
        data: messageBytes,
      );

      return true;
    } catch (e) {
      // Handle network or encoding errors
      String errorMessage;
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException') ||
          e.toString().contains('Connection')) {
        errorMessage = 'Cannot send move: Connection lost. Please check your internet connection.';
      } else {
        errorMessage = 'Failed to send move: ${e.toString()}';
      }
      
      _errorController.add(errorMessage);
      _isSubmitting = false;
      return false;
    } finally {
      // Reset submission flag after a short delay to prevent rapid-fire submissions
      // The server will send a state update or rejection message
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSubmitting = false;
      });
    }
  }

  /// Handle move rejection from server
  /// This should be called by the GameStateManager when it receives a move_rejected message
  void handleMoveRejection(String reason) {
    _isSubmitting = false;
    _errorController.add(reason);
  }

  /// Handle successful move (state update received)
  /// This should be called by the GameStateManager when it receives a state_update message
  void handleMoveSuccess() {
    _isSubmitting = false;
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
  }
}
