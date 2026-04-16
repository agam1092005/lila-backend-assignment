import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry', () {
    test('fromJson creates valid LeaderboardEntry', () {
      final json = {
        'username': 'TestPlayer',
        'wins': 10,
        'losses': 5,
        'winStreak': 3,
        'rank': 1,
      };

      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.username, 'TestPlayer');
      expect(entry.wins, 10);
      expect(entry.losses, 5);
      expect(entry.winStreak, 3);
      expect(entry.rank, 1);
    });

    test('toJson creates valid JSON', () {
      final entry = LeaderboardEntry(
        username: 'TestPlayer',
        wins: 10,
        losses: 5,
        winStreak: 3,
        rank: 1,
      );

      final json = entry.toJson();

      expect(json['username'], 'TestPlayer');
      expect(json['wins'], 10);
      expect(json['losses'], 5);
      expect(json['winStreak'], 3);
      expect(json['rank'], 1);
    });

    test('creates entry with all required fields', () {
      final entry = LeaderboardEntry(
        username: 'Player1',
        wins: 15,
        losses: 3,
        winStreak: 7,
        rank: 2,
      );

      expect(entry.username, 'Player1');
      expect(entry.wins, 15);
      expect(entry.losses, 3);
      expect(entry.winStreak, 7);
      expect(entry.rank, 2);
    });

    test('handles zero values correctly', () {
      final entry = LeaderboardEntry(
        username: 'NewPlayer',
        wins: 0,
        losses: 0,
        winStreak: 0,
        rank: 10,
      );

      expect(entry.wins, 0);
      expect(entry.losses, 0);
      expect(entry.winStreak, 0);
    });

    test('round-trip conversion preserves data', () {
      final original = LeaderboardEntry(
        username: 'TestUser',
        wins: 25,
        losses: 10,
        winStreak: 5,
        rank: 3,
      );

      final json = original.toJson();
      final restored = LeaderboardEntry.fromJson(json);

      expect(restored.username, original.username);
      expect(restored.wins, original.wins);
      expect(restored.losses, original.losses);
      expect(restored.winStreak, original.winStreak);
      expect(restored.rank, original.rank);
    });
  });
}
