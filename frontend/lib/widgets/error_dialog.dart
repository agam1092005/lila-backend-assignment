import 'package:flutter/material.dart';

/// ErrorDialog displays user-friendly error messages with optional retry action
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool canRetry;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.canRetry = false,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (canRetry && onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: Text(canRetry ? 'Cancel' : 'OK'),
        ),
      ],
    );
  }

  /// Show error dialog with standard configuration
  static Future<void> show({
    required BuildContext context,
    String title = 'Error',
    required String message,
    bool canRetry = false,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        canRetry: canRetry,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Show connection error dialog
  static Future<void> showConnectionError({
    required BuildContext context,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return show(
      context: context,
      title: 'Connection Error',
      message: 'Cannot connect to the game server. Please check your internet connection and try again.',
      canRetry: true,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  /// Show timeout error dialog
  static Future<void> showTimeoutError({
    required BuildContext context,
    String message = 'The operation timed out. Please try again.',
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return show(
      context: context,
      title: 'Timeout',
      message: message,
      canRetry: true,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  /// Show move rejection error dialog
  static Future<void> showMoveRejectionError({
    required BuildContext context,
    required String reason,
  }) {
    return show(
      context: context,
      title: 'Invalid Move',
      message: reason,
      canRetry: false,
    );
  }

  /// Show generic error dialog
  static Future<void> showGenericError({
    required BuildContext context,
    String message = 'An unexpected error occurred. Please try again.',
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return show(
      context: context,
      title: 'Error',
      message: message,
      canRetry: onRetry != null,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }
}

/// ConnectionStatusIndicator shows the current connection status
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final bool isReconnecting;
  final String? statusMessage;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
    this.isReconnecting = false,
    this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected && !isReconnecting) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    IconData icon;
    String message;

    if (isReconnecting) {
      backgroundColor = Colors.orange;
      icon = Icons.sync;
      message = statusMessage ?? 'Reconnecting...';
    } else {
      backgroundColor = Colors.red;
      icon = Icons.cloud_off;
      message = statusMessage ?? 'Disconnected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
