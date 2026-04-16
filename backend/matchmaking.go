package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
)

// MatchmakerMatchedHandler is called when Nakama finds a match between players
// This function is automatically invoked by Nakama's matchmaker when it pairs players
// based on their matchmaking properties (in this case, game mode)
func MatchmakerMatchedHandler(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, entries []runtime.MatchmakerEntry) (string, error) {
	// Verify we have exactly 2 players
	if len(entries) != 2 {
		logger.Error("Matchmaker matched with incorrect number of players: %d", len(entries))
		return "", runtime.NewError("Invalid match size", 13) // INTERNAL
	}

	// Extract game mode from the first player's properties
	// Both players should have the same game mode due to matchmaker query filtering
	gameMode := "classic" // default to classic mode
	if mode, ok := entries[0].GetProperties()["game_mode"]; ok {
		if modeStr, isString := mode.(string); isString {
			gameMode = modeStr
		}
	}

	logger.Info("Creating match for game mode: %s with players: %s, %s", 
		gameMode, entries[0].GetPresence().GetUserId(), entries[1].GetPresence().GetUserId())

	// Create match with game mode parameter
	// This parameter will be passed to the match handler's MatchInit function
	params := map[string]interface{}{
		"gameMode": gameMode,
	}

	// Create the match using the registered match handler
	matchID, err := nk.MatchCreate(ctx, matchLabel, params)
	if err != nil {
		logger.Error("Failed to create match: %v", err)
		return "", runtime.NewError("Failed to create match", 13) // INTERNAL
	}

	logger.Info("Match created with ID: %s for game mode: %s", matchID, gameMode)

	// Return the match ID - Nakama will automatically notify both players
	// and they will receive a MatchmakerMatched message with this match ID
	return matchID, nil
}
