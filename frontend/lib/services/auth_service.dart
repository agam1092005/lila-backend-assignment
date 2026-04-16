import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nakama/nakama.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication status enum
enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

/// Authentication error details
class AuthError {
  final String message;
  final bool canRetry;
  final int? retryAttempt;
  final int? maxRetries;

  AuthError({
    required this.message,
    this.canRetry = true,
    this.retryAttempt,
    this.maxRetries,
  });
}

/// AuthService handles Nakama authentication with device ID
/// Implements exponential backoff retry and session management
class AuthService {
  final NakamaBaseClient _client;
  Session? _session;
  final _statusController = StreamController<AuthStatus>.broadcast();
  final _errorController = StreamController<AuthError>.broadcast();
  AuthStatus _currentStatus = AuthStatus.unauthenticated;
  Timer? _sessionCheckTimer;
  
  // Exponential backoff configuration
  static const List<int> _retryDelays = [1, 2, 4, 8, 30]; // seconds
  int _retryAttempt = 0;
  
  // Session storage key
  static const String _sessionTokenKey = 'nakama_session_token';
  static const String _deviceIdKey = 'device_id';

  AuthService(this._client);

  /// Get current authentication status
  AuthStatus get status => _currentStatus;

  /// Get current session
  Session? get session => _session;

  /// Stream of authentication status changes
  Stream<AuthStatus> get statusStream => _statusController.stream;

  /// Stream of authentication errors
  Stream<AuthError> get errorStream => _errorController.stream;

  /// Check if currently authenticated
  bool get isAuthenticated => 
      _session != null && !_session!.isExpired && !_session!.isRefreshExpired;

  /// Authenticate with Nakama using device ID
  /// Implements exponential backoff retry on failure
  Future<Session> authenticate() async {
    _updateStatus(AuthStatus.authenticating);
    
    try {
      // Get or generate device ID
      final deviceId = await _getOrCreateDeviceId();
      
      // Try to restore session from storage
      final restoredSession = await _restoreSession();
      if (restoredSession != null && !restoredSession.isExpired) {
        _session = restoredSession;
        _updateStatus(AuthStatus.authenticated);
        _startSessionMonitoring();
        _retryAttempt = 0; // Reset retry counter on success
        return _session!;
      }

      // Authenticate with device ID
      _session = await _client.authenticateDevice(deviceId: deviceId);
      
      // Store session token securely
      await _storeSession(_session!);
      
      _updateStatus(AuthStatus.authenticated);
      _startSessionMonitoring();
      _retryAttempt = 0; // Reset retry counter on success
      
      return _session!;
    } catch (e) {
      _updateStatus(AuthStatus.error);
      
      // Determine error message based on error type
      String errorMessage;
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException') ||
          e.toString().contains('Connection')) {
        errorMessage = 'Cannot connect to game server. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Connection timed out. The server may be unavailable.';
      } else {
        errorMessage = 'Authentication failed: ${e.toString()}';
      }
      
      // Implement exponential backoff retry
      if (_retryAttempt < _retryDelays.length) {
        final delay = _retryDelays[_retryAttempt];
        _retryAttempt++;
        
        // Emit error with retry information
        _errorController.add(AuthError(
          message: '$errorMessage Retrying in $delay seconds... (Attempt $_retryAttempt/${_retryDelays.length})',
          canRetry: true,
          retryAttempt: _retryAttempt,
          maxRetries: _retryDelays.length,
        ));
        
        await Future.delayed(Duration(seconds: delay));
        return authenticate(); // Recursive retry
      } else {
        // Max retries reached
        _errorController.add(AuthError(
          message: '$errorMessage Maximum retry attempts reached. Please try again later.',
          canRetry: false,
          retryAttempt: _retryAttempt,
          maxRetries: _retryDelays.length,
        ));
        
        throw Exception('Authentication failed after $_retryAttempt retries: $e');
      }
    }
  }

  /// Re-authenticate when session expires
  Future<void> reAuthenticate() async {
    try {
      _session = null;
      await authenticate();
    } catch (e) {
      _errorController.add(AuthError(
        message: 'Failed to re-authenticate: ${e.toString()}',
        canRetry: true,
      ));
      rethrow;
    }
  }

  /// Get or create a persistent device ID
  Future<String> _getOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_deviceIdKey);
      
      if (deviceId == null) {
        // Generate a unique device ID
        deviceId = _generateDeviceId();
        await prefs.setString(_deviceIdKey, deviceId);
      }
      
      return deviceId;
    } catch (e) {
      // If storage fails, generate a temporary device ID
      return _generateDeviceId();
    }
  }

  /// Generate a unique device ID based on platform
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode;
    
    if (kIsWeb) {
      return 'web_${timestamp}_$random';
    } else if (Platform.isAndroid) {
      return 'android_${timestamp}_$random';
    } else if (Platform.isIOS) {
      return 'ios_${timestamp}_$random';
    } else {
      return 'unknown_${timestamp}_$random';
    }
  }

  /// Store session token securely in local storage
  Future<void> _storeSession(Session session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionTokenKey, session.token);
    } catch (e) {
      // Log error but don't fail authentication if storage fails
      print('Warning: Failed to store session token: $e');
    }
  }

  /// Restore session from local storage
  Future<Session?> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_sessionTokenKey);
      
      if (token == null) return null;
      
      // Restore session from token
      final session = Session.restore(
        token: token,
        refreshToken: '', // Device auth doesn't use refresh tokens
      );
      
      // Check if session is still valid
      if (session?.isExpired == true || session?.isRefreshExpired == true) {
        await prefs.remove(_sessionTokenKey);
        return null;
      }
      
      return session;
    } catch (e) {
      // If restoration fails, return null to trigger new authentication
      return null;
    }
  }

  /// Start monitoring session expiration
  void _startSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    
    // Check session every 30 seconds
    _sessionCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkSessionExpiration(),
    );
  }

  /// Check if session has expired and re-authenticate if needed
  Future<void> _checkSessionExpiration() async {
    if (_session == null) return;
    
    if (_session!.isExpired || _session!.isRefreshExpired) {
      _updateStatus(AuthStatus.unauthenticated);
      
      // Attempt re-authentication
      try {
        await reAuthenticate();
      } catch (e) {
        _updateStatus(AuthStatus.error);
        _errorController.add(AuthError(
          message: 'Session expired and re-authentication failed. Please restart the app.',
          canRetry: true,
        ));
      }
    }
  }

  /// Update authentication status and notify listeners
  void _updateStatus(AuthStatus newStatus) {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  /// Dispose resources
  void dispose() {
    _sessionCheckTimer?.cancel();
    _statusController.close();
    _errorController.close();
  }
}
