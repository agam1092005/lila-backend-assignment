import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';
import 'package:frontend/services/theme_manager.dart';
import 'package:frontend/models/leaderboard_entry.dart';
import 'package:frontend/services/leaderboard_service.dart';
import 'package:frontend/utils/responsive_helper.dart';

/// LeaderboardScreen displays the top 10 players with their statistics
/// Supports pull-to-refresh and handles loading/error states
class LeaderboardScreen extends StatefulWidget {
  final NakamaBaseClient nakamaClient;
  final ThemeManager themeManager;

  const LeaderboardScreen({
    super.key,
    required this.nakamaClient,
    required this.themeManager,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late LeaderboardService _leaderboardService;
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _leaderboardService = LeaderboardService(widget.nakamaClient);
    _loadLeaderboard();
  }

  /// Load leaderboard data from the server
  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get session from route arguments if available
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final session = args?['session'] as Session?;
      
      if (session == null) {
        throw Exception('No session available');
      }

      final entries = await _leaderboardService.fetchLeaderboard(
        session: session,
      );

      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : ResponsiveHelper.desktopMaxContentWidth,
          ),
          child: _buildBody(isMobile),
        ),
      ),
    );
  }

  /// Build the body based on current state
  Widget _buildBody(bool isMobile) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(isMobile);
    }

    if (_entries.isEmpty) {
      return _buildEmptyState(isMobile);
    }

    return _buildLeaderboardList(isMobile);
  }

  /// Build error state with retry button
  Widget _buildErrorState(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isMobile ? 64 : 48,
              color: Colors.red,
            ),
            SizedBox(height: isMobile ? 16 : 12),
            Text(
              'Failed to load leaderboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 22 : 20,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 6),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isMobile ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : 20),
            SizedBox(
              height: isMobile ? 56 : 48,
              child: ElevatedButton.icon(
                onPressed: _loadLeaderboard,
                icon: Icon(Icons.refresh, size: isMobile ? 28 : 24),
                label: Text(
                  'Retry',
                  style: TextStyle(fontSize: isMobile ? 18 : 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state when no entries are available
  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: isMobile ? 64 : 48,
              color: Colors.grey,
            ),
            SizedBox(height: isMobile ? 16 : 12),
            Text(
              'No leaderboard data yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 22 : 20,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 6),
            Text(
              'Play some games to see rankings!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isMobile ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the leaderboard list with pull-to-refresh
  Widget _buildLeaderboardList(bool isMobile) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          return _buildLeaderboardCard(_entries[index], isMobile);
        },
      ),
    );
  }

  /// Build a single leaderboard entry card
  Widget _buildLeaderboardCard(LeaderboardEntry entry, bool isMobile) {
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: isMobile ? 4.0 : 6.0,
        horizontal: isMobile ? 8.0 : 12.0,
      ),
      elevation: ResponsiveHelper.getCardElevation(
        MediaQuery.of(context).size.width,
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Row(
          children: [
            // Rank badge
            _buildRankBadge(entry.rank, isMobile),
            SizedBox(width: isMobile ? 16 : 20),
            
            // Username
            Expanded(
              child: Text(
                entry.username,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Stats
            _buildStatColumn('Wins', entry.wins, isMobile),
            SizedBox(width: isMobile ? 12 : 16),
            _buildStatColumn('Losses', entry.losses, isMobile),
            SizedBox(width: isMobile ? 12 : 16),
            _buildStatColumn('Streak', entry.winStreak, isMobile),
          ],
        ),
      ),
    );
  }

  /// Build rank badge with special styling for top 3
  Widget _buildRankBadge(int rank, bool isMobile) {
    Color badgeColor;
    IconData? icon;

    if (rank == 1) {
      badgeColor = Colors.amber;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = Colors.grey[400]!;
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300]!;
      icon = Icons.emoji_events;
    } else {
      badgeColor = Colors.blue;
    }

    final size = isMobile ? 56.0 : 48.0;
    final iconSize = isMobile ? 28.0 : 24.0;
    final fontSize = isMobile ? 20.0 : 18.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: Colors.white, size: iconSize)
            : Text(
                '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
      ),
    );
  }

  /// Build a stat column with label and value
  Widget _buildStatColumn(String label, int value, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: isMobile ? 13 : 12,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 2),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 16,
          ),
        ),
      ],
    );
  }
}

