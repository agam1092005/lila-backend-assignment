/// LeaderboardEntry represents a single player's statistics in the leaderboard
class LeaderboardEntry {
  final String username;
  final int wins;
  final int losses;
  final int winStreak;
  final int rank;

  LeaderboardEntry({
    required this.username,
    required this.wins,
    required this.losses,
    required this.winStreak,
    required this.rank,
  });

  /// Create LeaderboardEntry from JSON
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      username: json['username'] as String,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      winStreak: json['winStreak'] as int,
      rank: json['rank'] as int,
    );
  }

  /// Convert LeaderboardEntry to JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'wins': wins,
      'losses': losses,
      'winStreak': winStreak,
      'rank': rank,
    };
  }
}
