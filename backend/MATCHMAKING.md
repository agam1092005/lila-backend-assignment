# Matchmaking Implementation

## Overview

This implementation provides matchmaking functionality for the multiplayer Tic-Tac-Toe game using Nakama's built-in matchmaker system. Players are matched based on their selected game mode (classic or timer).

## Architecture

### Server-Side Components

1. **MatchmakerMatchedHandler** (`matchmaking.go`)
   - Automatically invoked by Nakama when two players are matched
   - Extracts game mode from player properties
   - Creates a new match with the appropriate game mode
   - Returns match ID to both clients

2. **Match Handler** (`match_handler.go`)
   - Receives game mode parameter during initialization
   - Manages game state for the specific mode
   - Handles timer logic for timer mode games

### Client-Side Integration

Clients use the Nakama client SDK to add themselves to the matchmaker. The matchmaking flow is:

1. **Client adds to matchmaker** (using Nakama SDK):
   ```dart
   // Example in Dart/Flutter
   final ticket = await socket.addMatchmaker(
     minCount: 2,
     maxCount: 2,
     query: '+properties.game_mode:classic',  // or 'timer'
     stringProperties: {
       'game_mode': 'classic',  // or 'timer'
     },
   );
   ```

2. **Nakama matches players**:
   - Nakama's matchmaker automatically pairs players with matching properties
   - Only players with the same `game_mode` property are matched together

3. **Server creates match**:
   - `MatchmakerMatchedHandler` is called with both players
   - A new match is created with the game mode parameter
   - Match ID is returned to Nakama

4. **Clients receive match notification**:
   - Both clients receive a `MatchmakerMatched` message
   - Message contains the match ID
   - Clients join the match using the match ID

5. **Clients join match**:
   ```dart
   // Example in Dart/Flutter
   await socket.joinMatch(matchId);
   ```

## Game Mode Filtering

The matchmaker uses Nakama's query syntax to filter players by game mode:

- **Query**: `+properties.game_mode:classic` or `+properties.game_mode:timer`
- **String Properties**: `{ 'game_mode': 'classic' }` or `{ 'game_mode': 'timer' }`

The `+` prefix in the query means "required" - players will only be matched if they have the same game mode property.

## Requirements Validation

This implementation validates the following requirements:

- **Requirement 2.1**: Players request matchmaking (via client SDK)
- **Requirement 2.2**: Server creates Game_Room when two players are matched
- **Requirement 12.6**: Players can select game mode (classic or timer)
- **Requirement 12.7**: Server only matches players with the same game mode

## Testing

Unit tests are provided in `matchmaking_test.go`:

- `TestMatchmakerMatchedHandler_InvalidPlayerCount`: Verifies error handling for incorrect player count
- `TestMatchmakerMatchedHandler_ThreePlayers`: Verifies rejection of 3+ player matches

Run tests with:
```bash
go test -v -run TestMatchmakerMatched
```

## Error Handling

The matchmaker matched handler includes error handling for:

1. **Invalid player count**: Returns error if not exactly 2 players
2. **Match creation failure**: Logs error and returns error to Nakama
3. **Missing game mode**: Defaults to "classic" mode

## Future Enhancements

Potential improvements for future iterations:

1. **Skill-based matchmaking**: Add player skill rating to properties
2. **Region-based matching**: Add geographic region to properties
3. **Matchmaking timeout**: Implement fallback for players waiting too long
4. **Party matchmaking**: Support pre-formed teams of 2 players
