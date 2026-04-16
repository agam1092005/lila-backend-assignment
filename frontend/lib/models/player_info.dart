/// PlayerInfo represents information about a player in a game
class PlayerInfo {
  final String userId;
  final String username;
  final String symbol; // "X" or "O"
  final String sessionId;

  PlayerInfo({
    required this.userId,
    required this.username,
    required this.symbol,
    required this.sessionId,
  });

  /// Create PlayerInfo from JSON
  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
    );
  }

  /// Convert PlayerInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'symbol': symbol,
      'sessionId': sessionId,
    };
  }

  @override
  String toString() {
    return 'PlayerInfo(userId: $userId, username: $username, symbol: $symbol)';
  }
}
