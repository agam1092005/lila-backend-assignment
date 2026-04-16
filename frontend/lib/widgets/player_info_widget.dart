import 'package:flutter/material.dart';
import '../models/player_info.dart';
import '../utils/responsive_helper.dart';

class PlayerInfoWidget extends StatelessWidget {
  final PlayerInfo player1;
  final PlayerInfo player2;
  final String currentTurn;

  const PlayerInfoWidget({
    super.key,
    required this.player1,
    required this.player2,
    required this.currentTurn,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);
    final spacing = ResponsiveHelper.getSpacing(screenWidth);

    if (isMobile) {
      // Mobile: vertical stack for better touch targets
      return Column(
        children: [
          _buildPlayerCard(context, player1, currentTurn == player1.symbol, isMobile),
          SizedBox(height: spacing * 0.75),
          _buildPlayerCard(context, player2, currentTurn == player2.symbol, isMobile),
        ],
      );
    } else {
      // Desktop: horizontal layout
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildPlayerCard(context, player1, currentTurn == player1.symbol, isMobile)),
          SizedBox(width: spacing),
          Expanded(child: _buildPlayerCard(context, player2, currentTurn == player2.symbol, isMobile)),
        ],
      );
    }
  }

  Widget _buildPlayerCard(BuildContext context, PlayerInfo player, bool isCurrentTurn, bool isMobile) {
    final padding = isMobile ? 16.0 : 12.0;
    final iconSize = ResponsiveHelper.getIconSize(MediaQuery.of(context).size.width);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentTurn
            ? Border.all(color: Theme.of(context).primaryColor, width: isMobile ? 3 : 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.username,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 16,
                        color: isCurrentTurn
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 6 : 4),
                Text(
                  'Symbol: ${player.symbol}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: isMobile ? 15 : 14,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentTurn)
            Icon(
              Icons.arrow_forward,
              color: Theme.of(context).primaryColor,
              size: iconSize,
            ),
        ],
      ),
    );
  }
}
