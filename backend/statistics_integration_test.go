package main

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/heroiclabs/nakama-common/api"
	"github.com/heroiclabs/nakama-common/runtime"
)

// TestStatisticsIntegration_WinByMove verifies that UpdatePlayerStatistics is called when a game ends via a winning move
func TestStatisticsIntegration_WinByMove(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	// Set up a game state where Player 1 can win with one move
	state := &GameState{
		Board: [][]string{
			{"X", "X", ""},
			{"O", "O", ""},
			{"", "", ""},
		},
		CurrentTurn: "X",
		Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
		Player2:     PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
		Outcome:     "ongoing",
		GameMode:    "classic",
	}

	// Create winning move signal
	signalData := map[string]interface{}{
		"type":   "move",
		"row":    float64(0),
		"col":    float64(2),
		"userId": "user1",
	}
	signalJSON, _ := json.Marshal(signalData)

	dispatcher := &mockDispatcher{}
	resultState, _ := match.MatchSignal(ctx, &mockLogger{}, nil, mockNk, dispatcher, 0, state, string(signalJSON))

	gameState, ok := resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify game ended with player1 winning
	if gameState.Outcome != "player1_wins" {
		t.Errorf("Expected outcome player1_wins, got %s", gameState.Outcome)
	}

	// Verify UpdatePlayerStatistics was called
	if !mockNk.statisticsUpdateCalled {
		t.Error("Expected UpdatePlayerStatistics to be called, but it wasn't")
	}
}

// TestStatisticsIntegration_WinByDisconnection verifies that UpdatePlayerStatistics is called when a player disconnects
func TestStatisticsIntegration_WinByDisconnection(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	state := &GameState{
		Board: [][]string{
			{"X", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn: "O",
		Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
		Player2:     PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
		Outcome:     "ongoing",
		GameMode:    "classic",
	}

	dispatcher := &mockDispatcher{}
	presence := &mockPresence{userID: "user2", username: "Player2"}
	resultState := match.MatchLeave(ctx, &mockLogger{}, nil, mockNk, dispatcher, 0, state, []runtime.Presence{presence})

	gameState, ok := resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify game ended with player1 winning (player2 disconnected)
	if gameState.Outcome != "player1_wins" {
		t.Errorf("Expected outcome player1_wins, got %s", gameState.Outcome)
	}

	// Verify UpdatePlayerStatistics was called
	if !mockNk.statisticsUpdateCalled {
		t.Error("Expected UpdatePlayerStatistics to be called, but it wasn't")
	}
}

// TestStatisticsIntegration_WinByTimerExpiration verifies that UpdatePlayerStatistics is called when timer expires
func TestStatisticsIntegration_WinByTimerExpiration(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	// Create state with expired timer
	expiredTime := time.Now().Unix() - 31 // 31 seconds ago (timer is 30 seconds)
	state := &GameState{
		Board: [][]string{
			{"X", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn:    "O",
		Player1:        PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
		Player2:        PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
		Outcome:        "ongoing",
		GameMode:       "timer",
		TimerStartTime: &expiredTime,
		TimerDuration:  30,
	}

	dispatcher := &mockDispatcher{}
	resultState := match.MatchLoop(ctx, &mockLogger{}, nil, mockNk, dispatcher, 0, state, nil)

	gameState, ok := resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify game ended with player1 winning (player2's timer expired)
	if gameState.Outcome != "player1_wins" {
		t.Errorf("Expected outcome player1_wins, got %s", gameState.Outcome)
	}

	// Verify UpdatePlayerStatistics was called
	if !mockNk.statisticsUpdateCalled {
		t.Error("Expected UpdatePlayerStatistics to be called, but it wasn't")
	}
}

// TestStatisticsIntegration_ErrorHandling verifies that errors from UpdatePlayerStatistics are logged but don't stop game flow
func TestStatisticsIntegration_ErrorHandling(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()
	mockNk := &mockNakamaModule{
		shouldReturnError: true,
	}
	match.ctx = ctx
	match.nk = mockNk

	// Set up a game state where Player 1 can win with one move
	state := &GameState{
		Board: [][]string{
			{"X", "X", ""},
			{"O", "O", ""},
			{"", "", ""},
		},
		CurrentTurn: "X",
		Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
		Player2:     PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
		Outcome:     "ongoing",
		GameMode:    "classic",
	}

	// Create winning move signal
	signalData := map[string]interface{}{
		"type":   "move",
		"row":    float64(0),
		"col":    float64(2),
		"userId": "user1",
	}
	signalJSON, _ := json.Marshal(signalData)

	dispatcher := &mockDispatcher{}
	resultState, _ := match.MatchSignal(ctx, &mockLogger{}, nil, mockNk, dispatcher, 0, state, string(signalJSON))

	gameState, ok := resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify game still ended correctly despite statistics error
	if gameState.Outcome != "player1_wins" {
		t.Errorf("Expected outcome player1_wins, got %s", gameState.Outcome)
	}

	// Verify UpdatePlayerStatistics was called (even though it returned an error)
	if !mockNk.statisticsUpdateCalled {
		t.Error("Expected UpdatePlayerStatistics to be called, but it wasn't")
	}
}

// TestStatisticsIntegration_NoCallWhenGameOngoing verifies that UpdatePlayerStatistics is NOT called when game is still ongoing
func TestStatisticsIntegration_NoCallWhenGameOngoing(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	state := &GameState{
		Board: [][]string{
			{"", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn: "X",
		Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
		Player2:     PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
		Outcome:     "ongoing",
		GameMode:    "classic",
	}

	// Make a non-winning move
	signalData := map[string]interface{}{
		"type":   "move",
		"row":    float64(0),
		"col":    float64(0),
		"userId": "user1",
	}
	signalJSON, _ := json.Marshal(signalData)

	dispatcher := &mockDispatcher{}
	resultState, _ := match.MatchSignal(ctx, &mockLogger{}, nil, mockNk, dispatcher, 0, state, string(signalJSON))

	gameState, ok := resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify game is still ongoing
	if gameState.Outcome != "ongoing" {
		t.Errorf("Expected outcome ongoing, got %s", gameState.Outcome)
	}

	// Verify UpdatePlayerStatistics was NOT called
	if mockNk.statisticsUpdateCalled {
		t.Error("Expected UpdatePlayerStatistics NOT to be called for ongoing game, but it was")
	}
}

// mockNakamaModule is a minimal mock that embeds the interface and only overrides what we need
type mockNakamaModule struct {
	runtime.NakamaModule
	statisticsUpdateCalled bool
	shouldReturnError      bool
}

// Override only the methods called by UpdatePlayerStatistics
func (m *mockNakamaModule) StorageRead(ctx context.Context, reads []*runtime.StorageRead) ([]*api.StorageObject, error) {
	return nil, nil
}

func (m *mockNakamaModule) StorageWrite(ctx context.Context, writes []*runtime.StorageWrite) ([]*api.StorageObjectAck, error) {
	m.statisticsUpdateCalled = true
	// Note: We can't easily capture the game state here since it's serialized to JSON in the writes
	// The important thing is that this method is called
	if m.shouldReturnError {
		return nil, &runtime.Error{Message: "Mock storage error"}
	}
	return nil, nil
}

func (m *mockNakamaModule) LeaderboardRecordWrite(ctx context.Context, id, ownerID, username string, score, subscore int64, metadata map[string]interface{}, overrideOperator *int) (*api.LeaderboardRecord, error) {
	if m.shouldReturnError {
		return nil, &runtime.Error{Message: "Mock leaderboard error"}
	}
	return nil, nil
}
