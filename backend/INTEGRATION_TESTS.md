# Integration Tests for Client-Server Communication

## Overview

This document describes the integration tests implemented for the multiplayer Tic-Tac-Toe game's client-server communication. These tests verify the complete flow of matchmaking, gameplay, and disconnection handling as specified in Task 25 of the implementation plan.

## Test File

**Location:** `backend/client_server_integration_test.go`

## Test Coverage

### 25.1 Full Matchmaking Flow

**Test:** `TestIntegration_FullMatchmakingFlow`

**Requirements Validated:** 2.1, 2.2, 2.3, 2.4

**What it tests:**
1. Match initialization with correct game mode
2. First client joins and is assigned Player 1 with symbol "X"
3. Second client joins and is assigned Player 2 with symbol "O"
4. Both clients receive initial game state broadcast
5. Third client is rejected when match is full

**Key Assertions:**
- Match label and tick rate are correct
- Initial board is empty 3x3 grid
- Current turn is set to "X"
- Player symbols are assigned deterministically (first = X, second = O)
- State update broadcast contains correct player information
- Match rejects additional join attempts when full

### 25.2 Full Gameplay Flow

**Test:** `TestIntegration_FullGameplayFlow`

**Requirements Validated:** 3.1, 3.6, 4.1, 5.1, 5.2, 5.3, 5.5

**What it tests:**
1. Two clients play a complete game
2. Each move is validated by the server
3. Board state updates are broadcast after each move
4. Win detection identifies the winner (diagonal win)
5. Game outcome is broadcast to both clients
6. Player statistics are updated when game ends
7. Moves are rejected after game ends

**Game Sequence:**
```
X | O | X
O | X | 
  |   | X
```
Player 1 (X) wins with diagonal: (0,0), (1,1), (2,2)

**Key Assertions:**
- Each move is applied to the correct board position
- Turn switches after each valid move
- State updates are broadcast after each move
- Win condition is detected correctly
- Final outcome is "player1_wins"
- Statistics update is called when game ends
- Invalid moves after game ends are rejected

### 25.3 Disconnection Handling

**Test:** `TestIntegration_DisconnectionHandling`

**Requirements Validated:** 1.5, 6.1, 6.2, 6.3

**What it tests:**
1. Player disconnects during active game
2. Server detects disconnection (verified to be within 10 seconds)
3. Remaining player receives win outcome
4. Disconnection notification is broadcast
5. Player statistics are updated

**Key Assertions:**
- Disconnection is detected immediately (< 10 seconds)
- Remaining player is awarded the win
- `player_disconnected` message is broadcast with correct player ID
- Final state update shows correct outcome
- Statistics are updated for disconnection win

## Additional Integration Tests

### Disconnection After Game Ended

**Test:** `TestIntegration_DisconnectionAfterGameEnded`

**What it tests:**
- Player disconnects after game has already ended
- Outcome remains unchanged
- Statistics are not updated again

### Both Players Disconnect

**Test:** `TestIntegration_BothPlayersDisconnect`

**What it tests:**
- First player disconnects → second player wins
- Second player disconnects → outcome remains unchanged
- Match state is preserved correctly

### Invalid Move Rejection

**Test:** `TestIntegration_InvalidMoveRejection`

**What it tests:**
- Wrong turn moves are rejected
- Moves to occupied positions are rejected
- Valid moves are accepted
- Rejection messages are broadcast
- State updates are broadcast for valid moves

## Running the Tests

### Run all integration tests:
```bash
cd backend
go test -v -run TestIntegration
```

### Run a specific integration test:
```bash
cd backend
go test -v -run TestIntegration_FullMatchmakingFlow
```

### Run all tests (including unit and property tests):
```bash
cd backend
go test -v ./...
```

## Test Architecture

### Mock Infrastructure

The tests use the existing mock infrastructure from `match_handler_test.go`:

- **mockLogger**: Implements `runtime.Logger` interface
- **mockPresence**: Implements `runtime.Presence` interface for player presence
- **mockDispatcher**: Implements `runtime.MatchDispatcher` for message broadcasting
- **mockNakamaModule**: Implements `runtime.NakamaModule` for Nakama operations
- **mockMatchData**: Implements `runtime.MatchData` for match messages

### Test Pattern

Each integration test follows this pattern:

1. **Setup**: Initialize match handler, create game state, set up mocks
2. **Execute**: Perform the action sequence (join, move, disconnect)
3. **Verify**: Assert expected outcomes and state changes
4. **Validate**: Check that broadcasts were sent with correct content

## Test Results

All integration tests pass successfully:

```
✓ Full matchmaking flow test passed
✓ Full gameplay flow test passed
✓ Disconnection handling test passed
✓ Disconnection after game ended test passed
✓ Both players disconnect test passed
✓ Invalid move rejection test passed
```

## Future Enhancements

For production deployment, consider adding:

1. **Real Nakama Instance Tests**: Tests that connect to actual Nakama server via Docker
2. **Load Testing**: Simulate multiple concurrent matches
3. **Network Latency Tests**: Test behavior under various network conditions
4. **Timer Mode Integration**: Comprehensive tests for timer-based gameplay
5. **Reconnection Tests**: Test client reconnection scenarios

## Notes

- These tests use mocks rather than a real Nakama instance for speed and reliability
- Tests verify the match handler logic and message flow
- For end-to-end testing with real clients, see the deployment testing section in the main README
- All tests complete in under 1 second
