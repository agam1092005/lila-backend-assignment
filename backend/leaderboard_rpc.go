package main

import (
	"context"
	"database/sql"
	"encoding/json"

	"github.com/heroiclabs/nakama-common/runtime"
)

// LeaderboardEntry represents a single entry in the leaderboard response
type LeaderboardEntry struct {
	Username  string `json:"username"`
	Wins      int    `json:"wins"`
	Losses    int    `json:"losses"`
	WinStreak int    `json:"winStreak"`
	Rank      int    `json:"rank"`
}

// LeaderboardResponse is the response structure for the leaderboard query
type LeaderboardResponse struct {
	Entries []LeaderboardEntry `json:"entries"`
}

// RpcGetLeaderboard queries the Nakama leaderboard for top 10 players
func RpcGetLeaderboard(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Query leaderboard for top 10 players sorted by wins (score) descending
	records, _, _, _, err := nk.LeaderboardRecordsList(ctx, leaderboardID, nil, 10, "", 0)
	if err != nil {
		logger.Error("Failed to query leaderboard: %v", err)
		return "", err
	}

	// Build response
	entries := make([]LeaderboardEntry, 0, len(records))
	
	for _, record := range records {
		// Extract losses from metadata
		losses := 0
		if record.Metadata != "" {
			var metadata map[string]interface{}
			if err := json.Unmarshal([]byte(record.Metadata), &metadata); err == nil {
				if lossesVal, ok := metadata["losses"].(float64); ok {
					losses = int(lossesVal)
				}
			}
		}

		entry := LeaderboardEntry{
			Username:  record.Username.Value,
			Wins:      int(record.Score),
			Losses:    losses,
			WinStreak: int(record.Subscore),
			Rank:      int(record.Rank),
		}
		entries = append(entries, entry)
	}

	// Marshal response
	response := LeaderboardResponse{
		Entries: entries,
	}

	responseData, err := json.Marshal(response)
	if err != nil {
		logger.Error("Failed to marshal leaderboard response: %v", err)
		return "", err
	}

	logger.Info("Leaderboard query returned %d entries", len(entries))
	return string(responseData), nil
}
