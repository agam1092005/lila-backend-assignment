package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
)

// InitModule initializes the Nakama runtime module
// This function is called when Nakama loads the module
func InitModule(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {
	logger.Info("Multiplayer Tic-Tac-Toe module loaded")
	
	// Register match handler
	if err := initializer.RegisterMatch(matchLabel, func(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule) (runtime.Match, error) {
		return &TicTacToeMatch{}, nil
	}); err != nil {
		logger.Error("Failed to register match handler: %v", err)
		return err
	}
	logger.Info("Match handler registered successfully")
	
	// Register matchmaker matched handler
	// This handler is called automatically when Nakama's matchmaker pairs two players
	// Clients add themselves to the matchmaker using the client SDK with game mode properties
	if err := initializer.RegisterMatchmakerMatched(MatchmakerMatchedHandler); err != nil {
		logger.Error("Failed to register matchmaker matched handler: %v", err)
		return err
	}
	logger.Info("Matchmaker matched handler registered successfully")
	
	// Register leaderboard RPC
	if err := initializer.RegisterRpc("get_leaderboard", RpcGetLeaderboard); err != nil {
		logger.Error("Failed to register leaderboard RPC: %v", err)
		return err
	}
	logger.Info("Leaderboard RPC registered successfully")
	
	// Create global leaderboard if it doesn't exist
	// This leaderboard tracks player wins (score) and win streaks (subscore)
	metadata := map[string]interface{}{}
	if err := nk.LeaderboardCreate(ctx, leaderboardID, false, "desc", "desc", "best", metadata); err != nil {
		// Leaderboard might already exist, log but don't fail
		logger.Warn("Leaderboard creation returned: %v (may already exist)", err)
	} else {
		logger.Info("Global leaderboard created successfully")
	}
	
	return nil
}
