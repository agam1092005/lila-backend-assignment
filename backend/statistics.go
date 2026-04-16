package main

import (
	"context"
	"encoding/json"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
)

// PlayerStats represents player statistics stored in Nakama storage
type PlayerStats struct {
	UserID      string `json:"userId"`
	Wins        int    `json:"wins"`
	Losses      int    `json:"losses"`
	WinStreak   int    `json:"winStreak"`
	GamesPlayed int    `json:"gamesPlayed"`
	LastUpdated int64  `json:"lastUpdated"` // Unix timestamp
}

// Storage collection and leaderboard constants
const (
	statsCollection    = "player_stats"
	leaderboardID      = "global_leaderboard"
)

// UpdatePlayerStatistics updates player statistics when a game ends
// This function increments wins/losses, updates win streaks, and writes to the leaderboard
func UpdatePlayerStatistics(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, gameState *GameState) error {
	// Determine winner and loser based on outcome
	var winnerID, loserID string
	var isDraw bool

	switch gameState.Outcome {
	case "player1_wins":
		winnerID = gameState.Player1.UserID
		loserID = gameState.Player2.UserID
	case "player2_wins":
		winnerID = gameState.Player2.UserID
		loserID = gameState.Player1.UserID
	case "draw":
		isDraw = true
	default:
		// Game is still ongoing or invalid outcome
		logger.Warn("UpdatePlayerStatistics called with outcome: %s", gameState.Outcome)
		return nil
	}

	if isDraw {
		// For draws, increment games played for both players but don't change wins/losses/streaks
		if err := updateStatsForDraw(ctx, logger, nk, gameState.Player1.UserID); err != nil {
			logger.Error("Failed to update stats for player 1 (draw): %v", err)
			return err
		}
		if err := updateStatsForDraw(ctx, logger, nk, gameState.Player2.UserID); err != nil {
			logger.Error("Failed to update stats for player 2 (draw): %v", err)
			return err
		}
		return nil
	}

	// Update winner's statistics
	if err := updateStatsForWin(ctx, logger, nk, winnerID); err != nil {
		logger.Error("Failed to update winner stats: %v", err)
		return err
	}

	// Update loser's statistics
	if err := updateStatsForLoss(ctx, logger, nk, loserID); err != nil {
		logger.Error("Failed to update loser stats: %v", err)
		return err
	}

	logger.Info("Statistics updated - Winner: %s, Loser: %s", winnerID, loserID)
	return nil
}

// updateStatsForWin updates statistics for a winning player
func updateStatsForWin(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, userID string) error {
	// Read current stats
	stats, err := readPlayerStats(ctx, nk, userID)
	if err != nil {
		logger.Error("Failed to read player stats for %s: %v", userID, err)
		return err
	}

	// Update stats for win
	stats.Wins++
	stats.WinStreak++
	stats.GamesPlayed++
	stats.LastUpdated = getCurrentTimestamp()

	// Write updated stats to storage
	if err := writePlayerStats(ctx, nk, stats); err != nil {
		logger.Error("Failed to write player stats for %s: %v", userID, err)
		return err
	}

	// Write to leaderboard (score = wins, subscore = win streak)
	if err := writeToLeaderboard(ctx, nk, stats); err != nil {
		logger.Error("Failed to write to leaderboard for %s: %v", userID, err)
		return err
	}

	logger.Info("Updated stats for winner %s: Wins=%d, WinStreak=%d", userID, stats.Wins, stats.WinStreak)
	return nil
}

// updateStatsForLoss updates statistics for a losing player
func updateStatsForLoss(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, userID string) error {
	// Read current stats
	stats, err := readPlayerStats(ctx, nk, userID)
	if err != nil {
		logger.Error("Failed to read player stats for %s: %v", userID, err)
		return err
	}

	// Update stats for loss
	stats.Losses++
	stats.WinStreak = 0 // Reset win streak on loss
	stats.GamesPlayed++
	stats.LastUpdated = getCurrentTimestamp()

	// Write updated stats to storage
	if err := writePlayerStats(ctx, nk, stats); err != nil {
		logger.Error("Failed to write player stats for %s: %v", userID, err)
		return err
	}

	// Write to leaderboard (score = wins, subscore = win streak)
	if err := writeToLeaderboard(ctx, nk, stats); err != nil {
		logger.Error("Failed to write to leaderboard for %s: %v", userID, err)
		return err
	}

	logger.Info("Updated stats for loser %s: Losses=%d, WinStreak=0", userID, stats.Losses)
	return nil
}

// updateStatsForDraw updates statistics for a player in a draw
func updateStatsForDraw(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, userID string) error {
	// Read current stats
	stats, err := readPlayerStats(ctx, nk, userID)
	if err != nil {
		logger.Error("Failed to read player stats for %s: %v", userID, err)
		return err
	}

	// Update stats for draw (only games played changes)
	stats.GamesPlayed++
	stats.LastUpdated = getCurrentTimestamp()

	// Write updated stats to storage
	if err := writePlayerStats(ctx, nk, stats); err != nil {
		logger.Error("Failed to write player stats for %s: %v", userID, err)
		return err
	}

	// Write to leaderboard (score = wins, subscore = win streak)
	if err := writeToLeaderboard(ctx, nk, stats); err != nil {
		logger.Error("Failed to write to leaderboard for %s: %v", userID, err)
		return err
	}

	logger.Info("Updated stats for draw %s: GamesPlayed=%d", userID, stats.GamesPlayed)
	return nil
}

// readPlayerStats reads player statistics from Nakama storage
func readPlayerStats(ctx context.Context, nk runtime.NakamaModule, userID string) (*PlayerStats, error) {
	// Read from storage
	objects, err := nk.StorageRead(ctx, []*runtime.StorageRead{
		{
			Collection: statsCollection,
			Key:        userID,
			UserID:     userID,
		},
	})

	if err != nil {
		return nil, err
	}

	// If no stats exist, create new stats
	if len(objects) == 0 {
		return &PlayerStats{
			UserID:      userID,
			Wins:        0,
			Losses:      0,
			WinStreak:   0,
			GamesPlayed: 0,
			LastUpdated: getCurrentTimestamp(),
		}, nil
	}

	// Parse existing stats
	var stats PlayerStats
	if err := json.Unmarshal([]byte(objects[0].Value), &stats); err != nil {
		return nil, err
	}

	return &stats, nil
}

// writePlayerStats writes player statistics to Nakama storage
func writePlayerStats(ctx context.Context, nk runtime.NakamaModule, stats *PlayerStats) error {
	// Marshal stats to JSON
	data, err := json.Marshal(stats)
	if err != nil {
		return err
	}

	// Write to storage
	_, err = nk.StorageWrite(ctx, []*runtime.StorageWrite{
		{
			Collection:      statsCollection,
			Key:             stats.UserID,
			UserID:          stats.UserID,
			Value:           string(data),
			PermissionRead:  2, // Public read
			PermissionWrite: 0, // No client write
		},
	})

	return err
}

// writeToLeaderboard writes player statistics to the Nakama leaderboard
func writeToLeaderboard(ctx context.Context, nk runtime.NakamaModule, stats *PlayerStats) error {
	// Write to leaderboard with wins as score and win streak as subscore
	metadata := map[string]interface{}{
		"losses": stats.Losses,
	}

	_, err := nk.LeaderboardRecordWrite(ctx, leaderboardID, stats.UserID, "", int64(stats.Wins), int64(stats.WinStreak), metadata, nil)
	return err
}

// getCurrentTimestamp returns the current Unix timestamp
func getCurrentTimestamp() int64 {
	return time.Now().Unix()
}
