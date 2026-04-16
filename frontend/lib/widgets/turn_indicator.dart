import 'package:flutter/material.dart';
import '../models/player_info.dart';
import '../utils/responsive_helper.dart';

class TurnIndicator extends StatelessWidget {
  final PlayerInfo currentPlayer;
  final bool isGameOver;

  const TurnIndicator({
    super.key,
    required this.currentPlayer,
    required this.isGameOver,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);
    final iconSize = ResponsiveHelper.getIconSize(screenWidth);

    if (isGameOver) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 28 : 24,
          vertical: isMobile ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Game Over',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 24 : 20,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 28 : 24,
        vertical: isMobile ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            color: Colors.white,
            size: iconSize,
          ),
          SizedBox(width: isMobile ? 16 : 12),
          Flexible(
            child: Text(
              "${currentPlayer.username}'s Turn (${currentPlayer.symbol})",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 20 : 18,
                    color: Colors.white,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
