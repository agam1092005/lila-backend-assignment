import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/responsive_helper.dart';

class GameBoard extends StatelessWidget {
  final GameState gameState;
  final Function(int row, int col)? onCellTap;
  final List<List<int>>? winningCells;

  const GameBoard({
    super.key,
    required this.gameState,
    this.onCellTap,
    this.winningCells,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);
    
    // Mobile: 90% of screen width (larger touch targets)
    // Desktop: fixed 400px (more compact)
    final boardSize = isMobile 
        ? (screenWidth * 0.9).clamp(280.0, 500.0) 
        : 400.0;
    final cellSize = boardSize / 3;

    return Container(
      width: boardSize,
      height: boardSize,
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
      child: Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(3, (col) {
                return Expanded(
                  child: _buildCell(context, row, col, cellSize, isMobile),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int row, int col, double cellSize, bool isMobile) {
    final cellValue = gameState.board[row][col];
    final isEmpty = cellValue.isEmpty;
    final isWinningCell = _isWinningCell(row, col);
    final canTap = isEmpty && !gameState.isGameOver && onCellTap != null;

    return GestureDetector(
      onTap: canTap ? () => onCellTap!(row, col) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: col < 2 ? BorderSide(color: Theme.of(context).dividerColor, width: 2) : BorderSide.none,
            bottom: row < 2 ? BorderSide(color: Theme.of(context).dividerColor, width: 2) : BorderSide.none,
          ),
          color: isWinningCell
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : canTap
                  ? Theme.of(context).hoverColor
                  : Colors.transparent,
        ),
        child: Center(
          child: Text(
            cellValue,
            style: TextStyle(
              // Mobile: larger symbols for better visibility
              // Desktop: smaller symbols for compact layout
              fontSize: isMobile ? cellSize * 0.6 : cellSize * 0.5,
              fontWeight: FontWeight.bold,
              color: isWinningCell
                  ? Theme.of(context).primaryColor
                  : cellValue == 'X'
                      ? Colors.blue
                      : cellValue == 'O'
                          ? Colors.red
                          : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  bool _isWinningCell(int row, int col) {
    if (winningCells == null) return false;
    return winningCells!.any((cell) => cell[0] == row && cell[1] == col);
  }
}
