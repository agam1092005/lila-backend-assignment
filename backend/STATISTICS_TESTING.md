# Statistics and Leaderboard Testing Guide

This document describes how to test the player statistics and leaderboard system.

## Components Implemented

### 1. Statistics Update Function (`statistics.go`)
- `UpdatePlayerStatistics`: Main function that updates player stats when games end
- `updateStatsForWin`: Increments winner's wins and win streak
- `updateStatsForLoss`: Increments loser's losses and resets win streak to 0
- `updateStatsForDraw`: Increments games played for both players (no change to wins/losses/streaks)
- `readPlayerStats`: Reads player statistics from Nakama storage
- `writePlayerStats`: Writes player statistics to Nakama storage
- `writeToLeaderboard`: Writes player stats to the global leaderboard

### 2. Leaderboard Query RPC (`leaderboard_rpc.go`)
- `RpcGetLeaderboard`: RPC handler that queries the top 10 players from the leaderboard
- Returns: username, wins, losses, win streak, and rank for each player

### 3. Integration Points
The statistics update function is called from the match handler in three places:
1. When a game ends due to a valid move (in `matchSignal` and `handleMessage`)
2. When a player disconnects during an active game (in `matchLeave`)
3. When the timer expires in timer mode (in `matchLoop`)

## Storage Schema

### Player Statistics (Nakama Storage)
- **Collection**: `player_stats`
- **Key**: `{userId}`
- **Value**: JSON object with:
  - `userId`: string
  - `wins`: int
  - `losses`: int
  - `winStreak`: int
  - `gamesPlayed`: int
  - `lastUpdated`: int64 (Unix timestamp)

### Leaderboard (Nakama Leaderboard)
- **Leaderboard ID**: `global_leaderboard`
- **Score**: wins count (primary sort, descending)
- **Subscore**: win streak (secondary sort, descending)
- **Metadata**: `{ "losses": number }`

## Manual Testing Steps

### Prerequisites
1. Start Nakama server with the compiled backend module
2. Have two clients ready to play games

### Test Case 1: Winner and Loser Stats Update
1. Play a game to completion where Player 1 wins
2. Query storage for both players:
   ```
   Collection: player_stats
   Key: {player1_userId}
   ```
3. Verify Player 1 stats:
   - wins = 1
   - losses = 0
   - winStreak = 1
   - gamesPlayed = 1
4. Verify Player 2 stats:
   - wins = 0
   - losses = 1
   - winStreak = 0
   - gamesPlayed = 1

### Test Case 2: Win Streak Increment
1. Player 1 wins a second game
2. Verify Player 1 stats:
   - wins = 2
   - winStreak = 2

### Test Case 3: Win Streak Reset on Loss
1. Player 1 loses a game
2. Verify Player 1 stats:
   - losses = 1
   - winStreak = 0 (reset)

### Test Case 4: Draw Handling
1. Play a game that ends in a draw
2. Verify both players:
   - wins unchanged
   - losses unchanged
   - winStreak unchanged
   - gamesPlayed incremented by 1

### Test Case 5: Leaderboard Query
1. Call the RPC: `get_leaderboard`
2. Verify response contains:
   - Top 10 players sorted by wins (descending)
   - Each entry has: username, wins, losses, winStreak, rank
3. Verify ties are broken by win streak

### Test Case 6: Disconnection Stats Update
1. Start a game
2. Have one player disconnect mid-game
3. Verify the remaining player gets a win
4. Verify the disconnected player gets a loss

### Test Case 7: Timer Expiry Stats Update (Timer Mode)
1. Start a game in timer mode
2. Let the timer expire for one player
3. Verify the opponent gets a win
4. Verify the player whose timer expired gets a loss

## RPC Testing

### Get Leaderboard RPC
**Endpoint**: `get_leaderboard`
**Method**: POST to `/v2/rpc/get_leaderboard`
**Payload**: Empty string or `{}`

**Expected Response**:
```json
{
  "entries": [
    {
      "username": "Player1",
      "wins": 10,
      "losses": 2,
      "winStreak": 5,
      "rank": 1
    },
    {
      "username": "Player2",
      "wins": 8,
      "losses": 4,
      "winStreak": 3,
      "rank": 2
    }
  ]
}
```

## Verification Checklist

- [ ] Winner's wins count increments
- [ ] Loser's losses count increments
- [ ] Winner's win streak increments
- [ ] Loser's win streak resets to 0
- [ ] Draw doesn't change wins/losses/streaks
- [ ] Draw increments games played for both players
- [ ] Leaderboard is sorted by wins (descending)
- [ ] Leaderboard ties are broken by win streak
- [ ] Leaderboard shows top 10 players
- [ ] Stats update on normal game end
- [ ] Stats update on disconnection
- [ ] Stats update on timer expiry
- [ ] RPC returns correct data format

## Requirements Validated

This implementation validates the following requirements:
- **11.1**: Winner's wins count increments
- **11.2**: Loser's losses count increments
- **11.3**: Winner's win streak increments
- **11.4**: Loser's win streak resets to 0
- **11.5**: Leaderboard is maintained and sorted by wins
- **11.6**: Leaderboard query returns top 10 players

## Design Properties Validated

This implementation validates the following design properties:
- **Property 14**: Statistics update correctly on game conclusion
- **Property 15**: Win streak management (increment on win, reset on loss, unchanged on draw)
- **Property 16**: Leaderboard sorting (descending by wins, ties broken by win streak)
