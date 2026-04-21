import 'dart:convert';
import 'package:nakama/nakama.dart';
import 'package:frontend/models/leaderboard_entry.dart';

/// LeaderboardService handles leaderboard queries with Nakama
class LeaderboardService {
  final NakamaBaseClient _client;

  LeaderboardService(this._client);

  /// Fetch the top 10 players from the leaderboard
  /// Returns a list of LeaderboardEntry objects
  /// Throws Exception if the RPC call fails
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required Session session,
  }) async {
    try {
      // Call the leaderboard RPC
      final result = await _client.rpc(
        session: session,
        id: 'get_leaderboard',
        payload: '',
      );

      // Parse the response - result is an Rpc object with payload as a String
      final payload = result as String;
      if (payload.isEmpty) {
        return [];
      }
      
      final responseData = json.decode(payload);
      final entries = responseData['entries'] as List<dynamic>? ?? [];

      // Convert to LeaderboardEntry objects
      return entries
          .map((entry) => LeaderboardEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }
}
