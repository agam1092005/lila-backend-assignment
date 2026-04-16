import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class OutcomeDialog extends StatelessWidget {
  final String outcome;
  final String? player1Username;
  final String? player2Username;
  final bool isDisconnection;
  final VoidCallback onReturnToMenu;

  const OutcomeDialog({
    super.key,
    required this.outcome,
    this.player1Username,
    this.player2Username,
    this.isDisconnection = false,
    required this.onReturnToMenu,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);
    final resultText = _getResultText();
    final resultIcon = _getResultIcon();
    final resultColor = _getResultColor(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 28 : 24),
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth * 0.9 : 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              resultIcon,
              size: isMobile ? 96 : 80,
              color: resultColor,
            ),
            SizedBox(height: isMobile ? 20 : 16),
            Text(
              resultText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 26 : 22,
                    color: resultColor,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isDisconnection) ...[
              SizedBox(height: isMobile ? 16 : 12),
              Text(
                'Player disconnected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isMobile ? 16 : 14,
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: isMobile ? 28 : 24),
            SizedBox(
              width: double.infinity,
              height: isMobile ? 56 : 48,
              child: ElevatedButton(
                onPressed: onReturnToMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Return to Menu',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getResultText() {
    if (outcome == 'player1_wins') {
      return '$player1Username Wins!';
    } else if (outcome == 'player2_wins') {
      return '$player2Username Wins!';
    } else if (outcome == 'draw') {
      return "It's a Draw!";
    }
    return 'Game Over';
  }

  IconData _getResultIcon() {
    if (outcome == 'draw') {
      return Icons.handshake;
    }
    return Icons.emoji_events;
  }

  Color _getResultColor(BuildContext context) {
    if (outcome == 'draw') {
      return Colors.orange;
    }
    return Colors.green;
  }

  static void show(
    BuildContext context, {
    required String outcome,
    String? player1Username,
    String? player2Username,
    bool isDisconnection = false,
    required VoidCallback onReturnToMenu,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OutcomeDialog(
        outcome: outcome,
        player1Username: player1Username,
        player2Username: player2Username,
        isDisconnection: isDisconnection,
        onReturnToMenu: onReturnToMenu,
      ),
    );
  }
}
