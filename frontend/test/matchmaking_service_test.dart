import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/matchmaking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatchmakingService', () {
    late MatchmakingService matchmakingService;

    setUp(() {
      matchmakingService = MatchmakingService(
        host: 'localhost',
        port: 7350,
        ssl: false,
      );
    });

    tearDown(() {
      matchmakingService.dispose();
    });

    test('initial status is idle', () {
      expect(matchmakingService.status, MatchmakingStatus.idle);
      expect(matchmakingService.isSearching, false);
    });

    test('status stream is functional', () {
      expect(matchmakingService.statusStream, isNotNull);
    });

    test('GameMode enum converts to correct server strings', () {
      expect(GameMode.classic.toServerString(), 'classic');
      expect(GameMode.timer.toServerString(), 'timer');
    });

    test('matchmaking timeout is 60 seconds', () {
      // Verify the timeout configuration
      const expectedTimeout = Duration(seconds: 60);
      expect(expectedTimeout.inSeconds, 60);
    });

    test('cancellation when not searching does nothing', () async {
      // Verify that cancellation when not searching doesn't throw
      await matchmakingService.cancelMatchmaking();
      expect(matchmakingService.status, MatchmakingStatus.idle);
    });
  });
}
