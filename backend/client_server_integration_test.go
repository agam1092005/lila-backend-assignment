package main

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
)

// TestIntegration_FullMatchmakingFlow tests the complete matchmaking flow
// Subtask 25.1: Test full matchmaking flow
// Requirements: 2.1, 2.2, 2.3, 2.4
func TestIntegration_FullMatchmakingFlow(t *testing.T) {
	// Initialize match handler
	match := &TicTacToeMatch{}
	ctx := context.Background()
	logger := &mockLogger{}
	mockNk := &mockNakamaModule{}

	// Step 1: Initialize match with classic mode
	params := map[string]interface{}{
		"gameMode": "classic",
	}
	state, tickRate, label := match.MatchInit(ctx, logger, nil, mockNk, params)

	// Verify match initialization
	if label != matchLabel {
		t.Errorf("Expected label %s, got %s", matchLabel, label)
	}
	if tickRate != 0 {
		t.Errorf("Expected tick rate 0 for classic mode, got %d", tickRate)
	}

	gameState, ok := state.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify initial game state
	if gameState.Outcome != "ongoing" {
		t.Errorf("Expected outcome ongoing, got %s", gameState.Outcome)
	}
	if gameState.CurrentTurn != "X" {
		t.Errorf("Expected current turn X, got %s", gameState.CurrentTurn)
	}

	// Step 2: First client joins (matchmaking assigns to match)
	dispatcher := &mockDispatcher{}
	presence1 := &mockPresence{
		userID:    "client1",
		username:  "Player1",
		sessionID: "session1",
	}

	// Verify join attempt is accepted
	_, accepted, reason := match.MatchJoinAttempt(ctx, logger, nil, mockNk, dispatcher, 0, gameState, presence1, nil)
	if !accepted {
		t.Errorf("Expected join to be accepted, got rejected with reason: %s", reason)
	}

	// Join first player
	resultState := match.MatchJoin(ctx, logger, nil, mockNk, dispatcher, 0, gameState, []runtime.Presence{presence1})
	gameState, ok = resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState after first join")
	}

	// Verify first player assignment
	if gameState.Player1.UserID != "client1" {
		t.Errorf("Expected Player1 UserID to be client1, got %s", gameState.Player1.UserID)
	}
	if gameState.Player1.Symbol != "X" {
		t.Errorf("Expected Player1 symbol to be X, got %s", gameState.Player1.Symbol)
	}
	if gameState.Player2.UserID != "" {
		t.Error("Expected Player2 to be empty before second player joins")
	}

	// Step 3: Second client joins (matchmaking assigns to same match)
	presence2 := &mockPresence{
		userID:    "client2",
		username:  "Player2",
		sessionID: "session2",
	}

	// Verify join attempt is accepted
	_, accepted, reason = match.MatchJoinAttempt(ctx, logger, nil, mockNk, dispatcher, 0, gameState, presence2, nil)
	if !accepted {
		t.Errorf("Expected join to be accepted, got rejected with reason: %s", reason)
	}

	// Join second player
	resultState = match.MatchJoin(ctx, logger, nil, mockNk, dispatcher, 0, gameState, []runtime.Presence{presence2})
	gameState, ok = resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState after second join")
	}

	// Verify second player assignment
	if gameState.Player2.UserID != "client2" {
		t.Errorf("Expected Player2 UserID to be client2, got %s", gameState.Player2.UserID)
	}
	if gameState.Player2.Symbol != "O" {
		t.Errorf("Expected Player2 symbol to be O, got %s", gameState.Player2.Symbol)
	}

	// Step 4: Verify both clients receive initial game state
	if len(dispatcher.messages) == 0 {
		t.Fatal("Expected initial game state broadcast, got no messages")
	}

	// Parse the broadcast message
	var stateUpdate StateUpdate
	if err := json.Unmarshal(dispatcher.messages[0], &stateUpdate); err != nil {
		t.Fatalf("Failed to parse initial state broadcast: %v", err)
	}

	// Verify initial state broadcast content
	if stateUpdate.Type != "state_update" {
		t.Errorf("Expected message type state_update, got %s", stateUpdate.Type)
	}
	if stateUpdate.CurrentTurn != "X" {
		t.Errorf("Expected current turn X, got %s", stateUpdate.CurrentTurn)
	}
	if stateUpdate.Outcome != "ongoing" {
		t.Errorf("Expected outcome ongoing, got %s", stateUpdate.Outcome)
	}
	if stateUpdate.Player1.UserID != "client1" {
		t.Errorf("Expected Player1 UserID client1, got %s", stateUpdate.Player1.UserID)
	}
	if stateUpdate.Player2.UserID != "client2" {
		t.Errorf("Expected Player2 UserID client2, got %s", stateUpdate.Player2.UserID)
	}

	// Verify board is empty
	for i := 0; i < 3; i++ {
		for j := 0; j < 3; j++ {
			if stateUpdate.Board[i][j] != "" {
				t.Errorf("Expected board[%d][%d] to be empty, got %s", i, j, stateUpdate.Board[i][j])
			}
		}
	}

	// Step 5: Verify third client cannot join (match is full)
	presence3 := &mockPresence{
		userID:    "client3",
		username:  "Player3",
		sessionID: "session3",
	}

	_, accepted, reason = match.MatchJoinAttempt(ctx, logger, nil, mockNk, dispatcher, 0, gameState, presence3, nil)
	if accepted {
		t.Error("Expected third join to be rejected, but it was accepted")
	}
	if reason != "Match is full" {
		t.Errorf("Expected rejection reason 'Match is full', got %s", reason)
	}

	t.Log("✓ Full matchmaking flow test passed")
}

// TestIntegration_FullGameplayFlow tests a complete game from start to finish
// Subtask 25.2: Test full gameplay flow
// Requirements: 3.1, 3.6, 4.1, 5.1, 5.2, 5.3, 5.5
func TestIntegration_FullGameplayFlow(t *testing.T) {
	// Initialize match and players
	match := &TicTacToeMatch{}
	ctx := context.Background()
	logger := &mockLogger{}
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	// Create initial game state with both players
	gameState := &GameState{
		Board: [][]string{
			{"", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn: "X",
		Player1:     PlayerInfo{UserID: "client1", Username: "Player1", Symbol: "X", SessionID: "session1"},
		Player2:     PlayerInfo{UserID: "client2", Username: "Player2", Symbol: "O", SessionID: "session2"},
		Outcome:     "ongoing",
		GameMode:    "classic",
	}

	dispatcher := &mockDispatcher{}

	// Play a complete game where Player 1 (X) wins
	// Game sequence:
	// X | O | X
	// O | X | 
	//   |   | X

	moves := []struct {
		userID      string
		row         int
		col         int
		expectedMsg string
	}{
		{"client1", 0, 0, "Player 1 move 1"}, // X at (0,0)
		{"client2", 0, 1, "Player 2 move 1"}, // O at (0,1)
		{"client1", 1, 1, "Player 1 move 2"}, // X at (1,1)
		{"client2", 1, 0, "Player 2 move 2"}, // O at (1,0)
		{"client1", 2, 2, "Player 1 move 3"}, // X at (2,2) - diagonal win
		{"client1", 0, 2, "Player 1 move 4"}, // X at (0,2) - completing row win
	}

	for i, move := range moves {
		// Skip moves after game ends
		if gameState.Outcome != "ongoing" {
			break
		}

		t.Logf("Move %d: Player %s at (%d, %d)", i+1, move.userID, move.row, move.col)

		// Create move signal
		signalData := map[string]interface{}{
			"type":   "move",
			"row":    float64(move.row),
			"col":    float64(move.col),
			"userId": move.userID,
		}
		signalJSON, _ := json.Marshal(signalData)

		// Clear previous messages
		dispatcher.messages = nil

		// Submit move
		resultState, errMsg := match.MatchSignal(ctx, logger, nil, mockNk, dispatcher, 0, gameState, string(signalJSON))
		if errMsg != "" {
			t.Fatalf("Move %d failed: %s", i+1, errMsg)
		}

		gameState, ok := resultState.(*GameState)
		if !ok {
			t.Fatal("State is not *GameState")
		}

		// Verify move was applied to board
		expectedSymbol := "X"
		if move.userID == "client2" {
			expectedSymbol = "O"
		}
		if gameState.Board[move.row][move.col] != expectedSymbol {
			t.Errorf("Move %d: Expected board[%d][%d] to be %s, got %s",
				i+1, move.row, move.col, expectedSymbol, gameState.Board[move.row][move.col])
		}

		// Verify state update was broadcast
		if len(dispatcher.messages) == 0 {
			t.Fatalf("Move %d: Expected state update broadcast, got no messages", i+1)
		}

		// Parse broadcast
		var stateUpdate StateUpdate
		if err := json.Unmarshal(dispatcher.messages[0], &stateUpdate); err != nil {
			t.Fatalf("Move %d: Failed to parse state update: %v", i+1, err)
		}

		// Verify broadcast contains updated board
		if stateUpdate.Board[move.row][move.col] != expectedSymbol {
			t.Errorf("Move %d: Broadcast board[%d][%d] expected %s, got %s",
				i+1, move.row, move.col, expectedSymbol, stateUpdate.Board[move.row][move.col])
		}

		t.Logf("  Board state: %v", gameState.Board)
		t.Logf("  Outcome: %s, Turn: %s", gameState.Outcome, gameState.CurrentTurn)
	}

	// Verify game ended with Player 1 winning
	if gameState.Outcome != "player1_wins" {
		t.Errorf("Expected outcome player1_wins, got %s", gameState.Outcome)
	}

	// Verify final state broadcast includes outcome
	var finalUpdate StateUpdate
	if err := json.Unmarshal(dispatcher.messages[0], &finalUpdate); err != nil {
		t.Fatalf("Failed to parse final state update: %v", err)
	}

	if finalUpdate.Outcome != "player1_wins" {
		t.Errorf("Expected final broadcast outcome player1_wins, got %s", finalUpdate.Outcome)
	}

	// Verify statistics were updated
	if !mockNk.statisticsUpdateCalled {
		t.Error("Expected UpdatePlayerStatistics to be called when game ended")
	}

	// Test invalid move after game ends
	dispatcher.messages = nil
	signalData := map[string]interface{}{
		"type":   "move",
		"row":    float64(2),
		"col":    float64(0),
		"userId": "client2",
	}
	signalJSON, _ := json.Marshal(signalData)

	_, errMsg := match.MatchSignal(ctx, logger, nil, mockNk, dispatcher, 0, gameState, string(signalJSON))
	if errMsg == "" {
		t.Error("Expected move to be rejected after game ended, but it was accepted")
	}

	t.Log("✓ Full gameplay flow test passed")
}

// TestIntegration_DisconnectionHandling tests player disconnection during active game
// Subtask 25.3: Test disconnection handling
// Requirements: 1.5, 6.1, 6.2, 6.3
func TestIntegration_DisconnectionHandling(t *testing.T) {
	// Initialize match and players
	match := &TicTacToeMatch{}
	ctx := context.Background()
	logger := &mockLogger{}
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	// Create game state with ongoing game
	gameState := &GameState{
		Board: [][]string{
			{"X", "O", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn: "X",
		Player1:     PlayerInfo{UserID: "client1", Username: "Player1", Symbol: "X", SessionID: "session1"},
		Player2:     PlayerInfo{UserID: "client2", Username: "Player2", Symbol: "O", SessionID: "session2"},
		Outcome:     "ongoing",
		GameMode:    "classic",
	}

	dispatcher := &mockDispatcher{}

	// Record start time to verify detection within 10 seconds
	startTime := time.Now()

	// Simulate Player 2 disconnection
	presence2 := &mockPresence{
		userID:    "client2",
		username:  "Player2",
		sessionID: "session2",
	}

	resultState := match.MatchLeave(ctx, logger, nil, mockNk, dispatcher, 0, gameState, []runtime.Presence{presence2})

	// Verify detection time (should be immediate in this test)
	detectionTime := time.Since(startTime)
	if detectionTime > 10*time.Second {
		t.Errorf("Expected disconnection detection within 10 seconds, took %v", detectionTime)
	}

	gameState, ok := resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify remaining client receives win outcome
	if gameState.Outcome != "player1_wins" {
		t.Errorf("Expected outcome player1_wins after Player 2 disconnected, got %s", gameState.Outcome)
	}

	// Verify disconnection notification was broadcast
	if len(dispatcher.messages) < 1 {
		t.Fatal("Expected disconnection notification, got no messages")
	}

	// Parse disconnection message
	var disconnectMsg PlayerDisconnected
	foundDisconnectMsg := false
	for _, msg := range dispatcher.messages {
		if err := json.Unmarshal(msg, &disconnectMsg); err == nil {
			if disconnectMsg.Type == "player_disconnected" {
				foundDisconnectMsg = true
				break
			}
		}
	}

	if !foundDisconnectMsg {
		t.Error("Expected player_disconnected message to be broadcast")
	} else {
		if disconnectMsg.PlayerID != "client2" {
			t.Errorf("Expected disconnected player ID client2, got %s", disconnectMsg.PlayerID)
		}
	}

	// Verify final state update was broadcast
	var stateUpdate StateUpdate
	foundStateUpdate := false
	for _, msg := range dispatcher.messages {
		if err := json.Unmarshal(msg, &stateUpdate); err == nil {
			if stateUpdate.Type == "state_update" {
				foundStateUpdate = true
				break
			}
		}
	}

	if !foundStateUpdate {
		t.Error("Expected state_update message to be broadcast")
	} else {
		if stateUpdate.Outcome != "player1_wins" {
			t.Errorf("Expected state update outcome player1_wins, got %s", stateUpdate.Outcome)
		}
	}

	// Verify statistics were updated
	if !mockNk.statisticsUpdateCalled {
		t.Error("Expected UpdatePlayerStatistics to be called on disconnection")
	}

	t.Log("✓ Disconnection handling test passed")
}

// TestIntegration_DisconnectionAfterGameEnded verifies no outcome change if player disconnects after game ends
func TestIntegration_DisconnectionAfterGameEnded(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()
	logger := &mockLogger{}
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	// Create game state where game already ended
	gameState := &GameState{
		Board: [][]string{
			{"X", "X", "X"},
			{"O", "O", ""},
			{"", "", ""},
		},
		CurrentTurn: "O",
		Player1:     PlayerInfo{UserID: "client1", Username: "Player1", Symbol: "X", SessionID: "session1"},
		Player2:     PlayerInfo{UserID: "client2", Username: "Player2", Symbol: "O", SessionID: "session2"},
		Outcome:     "player1_wins",
		GameMode:    "classic",
	}

	dispatcher := &mockDispatcher{}
	presence2 := &mockPresence{
		userID:    "client2",
		username:  "Player2",
		sessionID: "session2",
	}

	resultState := match.MatchLeave(ctx, logger, nil, mockNk, dispatcher, 0, gameState, []runtime.Presence{presence2})

	gameState, ok := resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify outcome remains unchanged
	if gameState.Outcome != "player1_wins" {
		t.Errorf("Expected outcome to remain player1_wins, got %s", gameState.Outcome)
	}

	// Verify statistics were NOT updated again (game already ended)
	if mockNk.statisticsUpdateCalled {
		t.Error("Expected UpdatePlayerStatistics NOT to be called when game already ended")
	}

	t.Log("✓ Disconnection after game ended test passed")
}

// TestIntegration_BothPlayersDisconnect verifies match cleanup when both players disconnect
func TestIntegration_BothPlayersDisconnect(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()
	logger := &mockLogger{}
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	gameState := &GameState{
		Board: [][]string{
			{"X", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn: "O",
		Player1:     PlayerInfo{UserID: "client1", Username: "Player1", Symbol: "X", SessionID: "session1"},
		Player2:     PlayerInfo{UserID: "client2", Username: "Player2", Symbol: "O", SessionID: "session2"},
		Outcome:     "ongoing",
		GameMode:    "classic",
	}

	dispatcher := &mockDispatcher{}

	// First player disconnects
	presence1 := &mockPresence{userID: "client1", username: "Player1", sessionID: "session1"}
	resultState := match.MatchLeave(ctx, logger, nil, mockNk, dispatcher, 0, gameState, []runtime.Presence{presence1})
	gameState, _ = resultState.(*GameState)

	// Verify Player 2 wins
	if gameState.Outcome != "player2_wins" {
		t.Errorf("Expected player2_wins after Player 1 disconnected, got %s", gameState.Outcome)
	}

	// Second player disconnects
	presence2 := &mockPresence{userID: "client2", username: "Player2", sessionID: "session2"}
	resultState = match.MatchLeave(ctx, logger, nil, mockNk, dispatcher, 0, gameState, []runtime.Presence{presence2})
	gameState, _ = resultState.(*GameState)

	// Outcome should remain player2_wins (game already ended)
	if gameState.Outcome != "player2_wins" {
		t.Errorf("Expected outcome to remain player2_wins, got %s", gameState.Outcome)
	}

	t.Log("✓ Both players disconnect test passed")
}

// TestIntegration_InvalidMoveRejection tests that invalid moves are properly rejected and broadcast
func TestIntegration_InvalidMoveRejection(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()
	logger := &mockLogger{}
	mockNk := &mockNakamaModule{}
	match.ctx = ctx
	match.nk = mockNk

	gameState := &GameState{
		Board: [][]string{
			{"X", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn: "O",
		Player1:     PlayerInfo{UserID: "client1", Username: "Player1", Symbol: "X", SessionID: "session1"},
		Player2:     PlayerInfo{UserID: "client2", Username: "Player2", Symbol: "O", SessionID: "session2"},
		Outcome:     "ongoing",
		GameMode:    "classic",
	}

	dispatcher := &mockDispatcher{}

	testCases := []struct {
		name        string
		userID      string
		row         int
		col         int
		expectError bool
		description string
	}{
		{
			name:        "Wrong turn",
			userID:      "client1",
			row:         1,
			col:         1,
			expectError: true,
			description: "Player 1 tries to move when it's Player 2's turn",
		},
		{
			name:        "Position occupied",
			userID:      "client2",
			row:         0,
			col:         0,
			expectError: true,
			description: "Player 2 tries to move to occupied position",
		},
		{
			name:        "Valid move",
			userID:      "client2",
			row:         1,
			col:         1,
			expectError: false,
			description: "Player 2 makes valid move",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			dispatcher.messages = nil

			signalData := map[string]interface{}{
				"type":   "move",
				"row":    float64(tc.row),
				"col":    float64(tc.col),
				"userId": tc.userID,
			}
			signalJSON, _ := json.Marshal(signalData)

			_, errMsg := match.MatchSignal(ctx, logger, nil, mockNk, dispatcher, 0, gameState, string(signalJSON))

			if tc.expectError {
				if errMsg == "" {
					t.Errorf("%s: Expected error, but move was accepted", tc.description)
				}
				// Verify rejection message was broadcast
				if len(dispatcher.messages) == 0 {
					t.Errorf("%s: Expected rejection message broadcast", tc.description)
				}
			} else {
				if errMsg != "" {
					t.Errorf("%s: Expected move to be accepted, got error: %s", tc.description, errMsg)
				}
				// Verify state update was broadcast
				if len(dispatcher.messages) == 0 {
					t.Errorf("%s: Expected state update broadcast", tc.description)
				}
			}
		})
	}

	t.Log("✓ Invalid move rejection test passed")
}
