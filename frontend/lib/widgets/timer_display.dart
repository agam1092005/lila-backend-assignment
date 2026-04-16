import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class TimerDisplay extends StatelessWidget {
  final int? timerRemaining;
  final bool isTimerMode;

  const TimerDisplay({
    super.key,
    required this.timerRemaining,
    required this.isTimerMode,
  });

  @override
  Widget build(BuildContext context) {
    // Hide in classic mode
    if (!isTimerMode) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);
    final seconds = timerRemaining ?? 0;
    final isLowTime = seconds < 10;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 20,
        vertical: isMobile ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.shade100 : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLowTime ? Colors.red : Theme.of(context).primaryColor,
          width: isMobile ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLowTime ? Colors.red : Theme.of(context).primaryColor).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isLowTime ? Colors.red : Theme.of(context).primaryColor,
            size: isMobile ? 32 : 28,
          ),
          SizedBox(width: isMobile ? 12 : 8),
          Text(
            '$seconds',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 36 : 32,
                  color: isLowTime ? Colors.red : Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            's',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: isMobile ? 20 : 18,
                  color: isLowTime ? Colors.red : Theme.of(context).primaryColor,
                ),
          ),
        ],
      ),
    );
  }
}
