package main

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
)

// TestMatchInit verifies that matchInit creates an empty 3x3 board and sets current turn to X
func TestMatchInit(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	tests := []struct {
		name     string
		params   map[string]interface{}
		wantMode string
		wantTick int
	}{
		{
			name:     "Classic mode initialization",
			params:   map[string]interface{}{"gameMode": "classic"},
			wantMode: "classic",
			wantTick: 0,
		},
		{
			name:     "Timer mode initialization",
			params:   map[string]interface{}{"gameMode": "timer"},
			wantMode: "timer",
			wantTick: 1,
		},
		{
			name:     "Default to classic mode",
			params:   map[string]interface{}{},
			wantMode: "classic",
			wantTick: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			state, tickRate, label := match.MatchInit(ctx, &mockLogger{}, nil, nil, tt.params)

			// Verify label
			if label != matchLabel {
				t.Errorf("Expected label %s, got %s", matchLabel, label)
			}

			// Verify tick rate
			if tickRate != tt.wantTick {
				t.Errorf("Expected tick rate %d, got %d", tt.wantTick, tickRate)
			}

			// Verify state
			gameState, ok := state.(*GameState)
			if !ok {
				t.Fatal("State is not *GameState")
			}

			// Verify board is empty 3x3
			if len(gameState.Board) != 3 {
				t.Errorf("Expected 3 rows, got %d", len(gameState.Board))
			}
			for i, row := range gameState.Board {
				if len(row) != 3 {
					t.Errorf("Row %d: expected 3 columns, got %d", i, len(row))
				}
				for j, cell := range row {
					if cell != "" {
						t.Errorf("Cell [%d][%d]: expected empty, got %s", i, j, cell)
					}
				}
			}

			// Verify current turn is X
			if gameState.CurrentTurn != "X" {
				t.Errorf("Expected current turn X, got %s", gameState.CurrentTurn)
			}

			// Verify outcome is ongoing
			if gameState.Outcome != "ongoing" {
				t.Errorf("Expected outcome ongoing, got %s", gameState.Outcome)
			}

			// Verify game mode
			if gameState.GameMode != tt.wantMode {
				t.Errorf("Expected game mode %s, got %s", tt.wantMode, gameState.GameMode)
			}

			// Verify timer duration
			if gameState.TimerDuration != 30 {
				t.Errorf("Expected timer duration 30, got %d", gameState.TimerDuration)
			}

			// Verify timer start time is nil initially
			if gameState.TimerStartTime != nil {
				t.Errorf("Expected timer start time to be nil, got %v", gameState.TimerStartTime)
			}
		})
	}
}

// TestMatchJoinAttempt verifies that join attempts are validated correctly
func TestMatchJoinAttempt(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	tests := []struct {
		name       string
		state      *GameState
		wantAccept bool
		wantReason string
	}{
		{
			name: "Accept join when no players",
			state: &GameState{
				Player1: PlayerInfo{},
				Player2: PlayerInfo{},
			},
			wantAccept: true,
			wantReason: "",
		},
		{
			name: "Accept join when one player",
			state: &GameState{
				Player1: PlayerInfo{UserID: "user1"},
				Player2: PlayerInfo{},
			},
			wantAccept: true,
			wantReason: "",
		},
		{
			name: "Reject join when match is full",
			state: &GameState{
				Player1: PlayerInfo{UserID: "user1"},
				Player2: PlayerInfo{UserID: "user2"},
			},
			wantAccept: false,
			wantReason: "Match is full",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			presence := &mockPresence{userID: "user3"}
			_, accept, reason := match.MatchJoinAttempt(ctx, &mockLogger{}, nil, nil, nil, 0, tt.state, presence, nil)

			if accept != tt.wantAccept {
				t.Errorf("Expected accept %v, got %v", tt.wantAccept, accept)
			}

			if reason != tt.wantReason {
				t.Errorf("Expected reason %q, got %q", tt.wantReason, reason)
			}
		})
	}
}

// TestMatchJoin verifies that players are assigned symbols deterministically
func TestMatchJoin(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	tests := []struct {
		name              string
		initialState      *GameState
		presences         []runtime.Presence
		wantPlayer1Symbol string
		wantPlayer2Symbol string
		wantTimerStarted  bool
	}{
		{
			name: "First player gets X",
			initialState: &GameState{
				Board:       make([][]string, 3),
				CurrentTurn: "X",
				Player1:     PlayerInfo{},
				Player2:     PlayerInfo{},
				Outcome:     "ongoing",
				GameMode:    "classic",
			},
			presences: []runtime.Presence{
				&mockPresence{userID: "user1", username: "Player1", sessionID: "session1"},
			},
			wantPlayer1Symbol: "X",
			wantPlayer2Symbol: "",
			wantTimerStarted:  false,
		},
		{
			name: "Second player gets O",
			initialState: &GameState{
				Board:       make([][]string, 3),
				CurrentTurn: "X",
				Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X", SessionID: "session1"},
				Player2:     PlayerInfo{},
				Outcome:     "ongoing",
				GameMode:    "classic",
			},
			presences: []runtime.Presence{
				&mockPresence{userID: "user2", username: "Player2", sessionID: "session2"},
			},
			wantPlayer1Symbol: "X",
			wantPlayer2Symbol: "O",
			wantTimerStarted:  false,
		},
		{
			name: "Timer starts when both players join in timer mode",
			initialState: &GameState{
				Board:       make([][]string, 3),
				CurrentTurn: "X",
				Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X", SessionID: "session1"},
				Player2:     PlayerInfo{},
				Outcome:     "ongoing",
				GameMode:    "timer",
			},
			presences: []runtime.Presence{
				&mockPresence{userID: "user2", username: "Player2", sessionID: "session2"},
			},
			wantPlayer1Symbol: "X",
			wantPlayer2Symbol: "O",
			wantTimerStarted:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			dispatcher := &mockDispatcher{}
			state := match.MatchJoin(ctx, &mockLogger{}, nil, nil, dispatcher, 0, tt.initialState, tt.presences)

			gameState, ok := state.(*GameState)
			if !ok {
				t.Fatal("State is not *GameState")
			}

			// Verify player 1 symbol
			if gameState.Player1.Symbol != tt.wantPlayer1Symbol {
				t.Errorf("Expected Player1 symbol %s, got %s", tt.wantPlayer1Symbol, gameState.Player1.Symbol)
			}

			// Verify player 2 symbol
			if gameState.Player2.Symbol != tt.wantPlayer2Symbol {
				t.Errorf("Expected Player2 symbol %s, got %s", tt.wantPlayer2Symbol, gameState.Player2.Symbol)
			}

			// Verify timer started
			if tt.wantTimerStarted {
				if gameState.TimerStartTime == nil {
					t.Error("Expected timer to be started, but it was nil")
				}
			} else {
				if gameState.TimerStartTime != nil && gameState.Player1.UserID != "" && gameState.Player2.UserID != "" {
					t.Error("Expected timer to not be started in classic mode")
				}
			}
		})
	}
}

// TestMatchLeave verifies that disconnections award win to remaining player
func TestMatchLeave(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	tests := []struct {
		name           string
		state          *GameState
		leavingUserID  string
		wantOutcome    string
	}{
		{
			name: "Player 1 leaves, Player 2 wins",
			state: &GameState{
				Board:       make([][]string, 3),
				CurrentTurn: "X",
				Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
				Player2:     PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
				Outcome:     "ongoing",
				GameMode:    "classic",
			},
			leavingUserID: "user1",
			wantOutcome:   "player2_wins",
		},
		{
			name: "Player 2 leaves, Player 1 wins",
			state: &GameState{
				Board:       make([][]string, 3),
				CurrentTurn: "X",
				Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
				Player2:     PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
				Outcome:     "ongoing",
				GameMode:    "classic",
			},
			leavingUserID: "user2",
			wantOutcome:   "player1_wins",
		},
		{
			name: "Player leaves after game ended, outcome unchanged",
			state: &GameState{
				Board:       make([][]string, 3),
				CurrentTurn: "X",
				Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
				Player2:     PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
				Outcome:     "player1_wins",
				GameMode:    "classic",
			},
			leavingUserID: "user2",
			wantOutcome:   "player1_wins",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			dispatcher := &mockDispatcher{}
			presence := &mockPresence{userID: tt.leavingUserID}
			state := match.MatchLeave(ctx, &mockLogger{}, nil, nil, dispatcher, 0, tt.state, []runtime.Presence{presence})

			gameState, ok := state.(*GameState)
			if !ok {
				t.Fatal("State is not *GameState")
			}

			if gameState.Outcome != tt.wantOutcome {
				t.Errorf("Expected outcome %s, got %s", tt.wantOutcome, gameState.Outcome)
			}
		})
	}
}

// TestMatchLoopTimerExpiration verifies that timer expiration awards win to opponent
func TestMatchLoopTimerExpiration(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	tests := []struct {
		name        string
		currentTurn string
		wantOutcome string
	}{
		{
			name:        "Player 1 timer expires, Player 2 wins",
			currentTurn: "X",
			wantOutcome: "player2_wins",
		},
		{
			name:        "Player 2 timer expires, Player 1 wins",
			currentTurn: "O",
			wantOutcome: "player1_wins",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create state with expired timer
			expiredTime := time.Now().Unix() - 31 // 31 seconds ago (timer is 30 seconds)
			state := &GameState{
				Board:          make([][]string, 3),
				CurrentTurn:    tt.currentTurn,
				Player1:        PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
				Player2:        PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
				Outcome:        "ongoing",
				GameMode:       "timer",
				TimerStartTime: &expiredTime,
				TimerDuration:  30,
			}

			dispatcher := &mockDispatcher{}
			resultState := match.MatchLoop(ctx, &mockLogger{}, nil, nil, dispatcher, 0, state, nil)

			gameState, ok := resultState.(*GameState)
			if !ok {
				t.Fatal("State is not *GameState")
			}

			if gameState.Outcome != tt.wantOutcome {
				t.Errorf("Expected outcome %s, got %s", tt.wantOutcome, gameState.Outcome)
			}
		})
	}
}

// TestMatchLoopTimerCountdown verifies that timer countdown broadcasts remaining time
func TestMatchLoopTimerCountdown(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	tests := []struct {
		name              string
		elapsedSeconds    int64
		wantRemainingMin  int
		wantRemainingMax  int
	}{
		{
			name:              "Timer just started",
			elapsedSeconds:    0,
			wantRemainingMin:  29,
			wantRemainingMax:  30,
		},
		{
			name:              "Timer halfway through",
			elapsedSeconds:    15,
			wantRemainingMin:  14,
			wantRemainingMax:  15,
		},
		{
			name:              "Timer almost expired",
			elapsedSeconds:    29,
			wantRemainingMin:  0,
			wantRemainingMax:  1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			startTime := time.Now().Unix() - tt.elapsedSeconds
			state := &GameState{
				Board: [][]string{
					{"", "", ""},
					{"", "", ""},
					{"", "", ""},
				},
				CurrentTurn:    "X",
				Player1:        PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
				Player2:        PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
				Outcome:        "ongoing",
				GameMode:       "timer",
				TimerStartTime: &startTime,
				TimerDuration:  30,
			}

			dispatcher := &mockDispatcher{}
			resultState := match.MatchLoop(ctx, &mockLogger{}, nil, nil, dispatcher, 0, state, nil)

			gameState, ok := resultState.(*GameState)
			if !ok {
				t.Fatal("State is not *GameState")
			}

			// Verify game is still ongoing
			if gameState.Outcome != "ongoing" {
				t.Errorf("Expected outcome ongoing, got %s", gameState.Outcome)
			}

			// Verify broadcast was sent
			if len(dispatcher.messages) == 0 {
				t.Error("Expected broadcast message, got none")
			} else {
				// Parse the broadcast message
				var stateUpdate StateUpdate
				if err := json.Unmarshal(dispatcher.messages[0], &stateUpdate); err != nil {
					t.Fatalf("Failed to parse broadcast message: %v", err)
				}

				// Verify timer remaining is within expected range
				if stateUpdate.TimerRemaining == nil {
					t.Error("Expected TimerRemaining to be set, got nil")
				} else {
					remaining := *stateUpdate.TimerRemaining
					if remaining < tt.wantRemainingMin || remaining > tt.wantRemainingMax {
						t.Errorf("Expected remaining time between %d and %d, got %d",
							tt.wantRemainingMin, tt.wantRemainingMax, remaining)
					}
				}
			}
		})
	}
}

// TestMatchLoopClassicMode verifies that matchLoop doesn't process timer logic in classic mode
func TestMatchLoopClassicMode(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	state := &GameState{
		Board: [][]string{
			{"", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn:    "X",
		Player1:        PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
		Player2:        PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
		Outcome:        "ongoing",
		GameMode:       "classic",
		TimerStartTime: nil,
		TimerDuration:  30,
	}

	dispatcher := &mockDispatcher{}
	resultState := match.MatchLoop(ctx, &mockLogger{}, nil, nil, dispatcher, 0, state, nil)

	gameState, ok := resultState.(*GameState)
	if !ok {
		t.Fatal("State is not *GameState")
	}

	// Verify game is still ongoing (no timer logic processed)
	if gameState.Outcome != "ongoing" {
		t.Errorf("Expected outcome ongoing, got %s", gameState.Outcome)
	}

	// Verify no broadcasts were sent (since no timer updates in classic mode)
	if len(dispatcher.messages) > 0 {
		t.Error("Expected no broadcast messages in classic mode, got some")
	}
}

// TestTimerResetOnValidMove verifies that timer resets when a valid move is made
func TestTimerResetOnValidMove(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	// Set up initial timer
	initialTime := time.Now().Unix() - 10 // 10 seconds ago
	state := &GameState{
		Board: [][]string{
			{"", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn:    "X",
		Player1:        PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
		Player2:        PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
		Outcome:        "ongoing",
		GameMode:       "timer",
		TimerStartTime: &initialTime,
		TimerDuration:  30,
	}

	// Create valid move request
	moveReq := MoveRequest{
		Type: "move",
		Row:  0,
		Col:  0,
	}
	data, _ := json.Marshal(moveReq)

	message := &mockMatchData{
		userID: "user1",
		data:   data,
	}

	dispatcher := &mockDispatcher{}
	match.handleMessage(ctx, &mockLogger{}, nil, nil, dispatcher, state, message)

	// Verify timer was reset
	if state.TimerStartTime == nil {
		t.Error("Expected timer to be reset, but it was nil")
	} else {
		// Timer should be reset to a recent time (within last 2 seconds)
		now := time.Now().Unix()
		if *state.TimerStartTime < now-2 || *state.TimerStartTime > now {
			t.Errorf("Expected timer to be reset to recent time, got %d (now: %d)", *state.TimerStartTime, now)
		}
	}

	// Verify turn switched to opponent
	if state.CurrentTurn != "O" {
		t.Errorf("Expected current turn to be O, got %s", state.CurrentTurn)
	}
}

// TestHandleMessage verifies that move messages are processed correctly
func TestHandleMessage(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

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

	// Create valid move request
	moveReq := MoveRequest{
		Type: "move",
		Row:  0,
		Col:  0,
	}
	data, _ := json.Marshal(moveReq)

	message := &mockMatchData{
		userID: "user1",
		data:   data,
	}

	dispatcher := &mockDispatcher{}
	match.handleMessage(ctx, &mockLogger{}, nil, nil, dispatcher, state, message)

	// Verify move was applied
	if state.Board[0][0] != "X" {
		t.Errorf("Expected board[0][0] to be X, got %s", state.Board[0][0])
	}

	// Verify turn switched
	if state.CurrentTurn != "O" {
		t.Errorf("Expected current turn to be O, got %s", state.CurrentTurn)
	}

	// Verify outcome is still ongoing
	if state.Outcome != "ongoing" {
		t.Errorf("Expected outcome to be ongoing, got %s", state.Outcome)
	}
}

// Mock implementations for testing

type mockLogger struct{}

func (m *mockLogger) Debug(format string, v ...interface{}) {}
func (m *mockLogger) Info(format string, v ...interface{})  {}
func (m *mockLogger) Warn(format string, v ...interface{})  {}
func (m *mockLogger) Error(format string, v ...interface{}) {}
func (m *mockLogger) WithField(key string, v interface{}) runtime.Logger { return m }
func (m *mockLogger) WithFields(fields map[string]interface{}) runtime.Logger { return m }
func (m *mockLogger) Fields() map[string]interface{} { return nil }

type mockPresence struct {
	userID    string
	sessionID string
	username  string
}

func (m *mockPresence) GetUserId() string    { return m.userID }
func (m *mockPresence) GetSessionId() string { return m.sessionID }
func (m *mockPresence) GetNodeId() string    { return "node1" }
func (m *mockPresence) GetHidden() bool      { return false }
func (m *mockPresence) GetPersistence() bool { return true }
func (m *mockPresence) GetUsername() string  { return m.username }
func (m *mockPresence) GetStatus() string    { return "" }
func (m *mockPresence) GetReason() runtime.PresenceReason { return runtime.PresenceReasonUnknown }

type mockDispatcher struct {
	messages [][]byte
}

func (m *mockDispatcher) BroadcastMessage(opCode int64, data []byte, presences []runtime.Presence, sender runtime.Presence, reliable bool) error {
	m.messages = append(m.messages, data)
	return nil
}

func (m *mockDispatcher) BroadcastMessageDeferred(opCode int64, data []byte, presences []runtime.Presence, sender runtime.Presence, reliable bool) error {
	return nil
}

func (m *mockDispatcher) MatchKick(presences []runtime.Presence) error {
	return nil
}

func (m *mockDispatcher) MatchLabelUpdate(label string) error {
	return nil
}

type mockMatchData struct {
	userID string
	data   []byte
}

func (m *mockMatchData) GetUserId() string      { return m.userID }
func (m *mockMatchData) GetSessionId() string   { return "session1" }
func (m *mockMatchData) GetNodeId() string      { return "node1" }
func (m *mockMatchData) GetHidden() bool        { return false }
func (m *mockMatchData) GetPersistence() bool   { return true }
func (m *mockMatchData) GetUsername() string    { return "TestUser" }
func (m *mockMatchData) GetStatus() string      { return "" }
func (m *mockMatchData) GetOpCode() int64       { return 1 }
func (m *mockMatchData) GetData() []byte        { return m.data }
func (m *mockMatchData) GetReliable() bool      { return true }
func (m *mockMatchData) GetReceiveTime() int64  { return time.Now().Unix() }
func (m *mockMatchData) GetReason() runtime.PresenceReason { return runtime.PresenceReasonUnknown }

// TestMatchSignal verifies that matchSignal handles move requests correctly
func TestMatchSignal(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

	tests := []struct {
		name           string
		state          *GameState
		signalData     map[string]interface{}
		wantOutcome    string
		wantBoardValue string
		wantBoardRow   int
		wantBoardCol   int
		wantTurn       string
		wantError      bool
	}{
		{
			name: "Valid move by Player 1",
			state: &GameState{
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
			},
			signalData: map[string]interface{}{
				"type":   "move",
				"row":    float64(0),
				"col":    float64(0),
				"userId": "user1",
			},
			wantOutcome:    "ongoing",
			wantBoardValue: "X",
			wantBoardRow:   0,
			wantBoardCol:   0,
			wantTurn:       "O",
			wantError:      false,
		},
		{
			name: "Valid move by Player 2",
			state: &GameState{
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
			},
			signalData: map[string]interface{}{
				"type":   "move",
				"row":    float64(1),
				"col":    float64(1),
				"userId": "user2",
			},
			wantOutcome:    "ongoing",
			wantBoardValue: "O",
			wantBoardRow:   1,
			wantBoardCol:   1,
			wantTurn:       "X",
			wantError:      false,
		},
		{
			name: "Invalid move - wrong turn",
			state: &GameState{
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
			},
			signalData: map[string]interface{}{
				"type":   "move",
				"row":    float64(0),
				"col":    float64(0),
				"userId": "user2",
			},
			wantOutcome:    "ongoing",
			wantBoardValue: "",
			wantBoardRow:   0,
			wantBoardCol:   0,
			wantTurn:       "X",
			wantError:      true,
		},
		{
			name: "Invalid move - position occupied",
			state: &GameState{
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
			},
			signalData: map[string]interface{}{
				"type":   "move",
				"row":    float64(0),
				"col":    float64(0),
				"userId": "user2",
			},
			wantOutcome:    "ongoing",
			wantBoardValue: "X",
			wantBoardRow:   0,
			wantBoardCol:   0,
			wantTurn:       "O",
			wantError:      true,
		},
		{
			name: "Invalid move - game ended",
			state: &GameState{
				Board: [][]string{
					{"X", "X", "X"},
					{"O", "O", ""},
					{"", "", ""},
				},
				CurrentTurn: "O",
				Player1:     PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
				Player2:     PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
				Outcome:     "player1_wins",
				GameMode:    "classic",
			},
			signalData: map[string]interface{}{
				"type":   "move",
				"row":    float64(2),
				"col":    float64(0),
				"userId": "user2",
			},
			wantOutcome:    "player1_wins",
			wantBoardValue: "",
			wantBoardRow:   2,
			wantBoardCol:   0,
			wantTurn:       "O",
			wantError:      true,
		},
		{
			name: "Winning move detection",
			state: &GameState{
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
			},
			signalData: map[string]interface{}{
				"type":   "move",
				"row":    float64(0),
				"col":    float64(2),
				"userId": "user1",
			},
			wantOutcome:    "player1_wins",
			wantBoardValue: "X",
			wantBoardRow:   0,
			wantBoardCol:   2,
			wantTurn:       "X", // Turn doesn't change when game ends
			wantError:      false,
		},
		{
			name: "Timer reset in timer mode",
			state: &GameState{
				Board: [][]string{
					{"", "", ""},
					{"", "", ""},
					{"", "", ""},
				},
				CurrentTurn:    "X",
				Player1:        PlayerInfo{UserID: "user1", Username: "Player1", Symbol: "X"},
				Player2:        PlayerInfo{UserID: "user2", Username: "Player2", Symbol: "O"},
				Outcome:        "ongoing",
				GameMode:       "timer",
				TimerDuration:  30,
				TimerStartTime: func() *int64 { t := time.Now().Unix() - 10; return &t }(),
			},
			signalData: map[string]interface{}{
				"type":   "move",
				"row":    float64(0),
				"col":    float64(0),
				"userId": "user1",
			},
			wantOutcome:    "ongoing",
			wantBoardValue: "X",
			wantBoardRow:   0,
			wantBoardCol:   0,
			wantTurn:       "O",
			wantError:      false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			dispatcher := &mockDispatcher{}
			signalJSON, _ := json.Marshal(tt.signalData)

			resultState, errMsg := match.MatchSignal(ctx, &mockLogger{}, nil, nil, dispatcher, 0, tt.state, string(signalJSON))

			gameState, ok := resultState.(*GameState)
			if !ok {
				t.Fatal("State is not *GameState")
			}

			// Verify error handling
			if tt.wantError && errMsg == "" {
				t.Error("Expected error message, got empty string")
			}
			if !tt.wantError && errMsg != "" {
				t.Errorf("Expected no error, got: %s", errMsg)
			}

			// Verify board state
			if gameState.Board[tt.wantBoardRow][tt.wantBoardCol] != tt.wantBoardValue {
				t.Errorf("Expected board[%d][%d] to be %s, got %s",
					tt.wantBoardRow, tt.wantBoardCol, tt.wantBoardValue, gameState.Board[tt.wantBoardRow][tt.wantBoardCol])
			}

			// Verify outcome
			if gameState.Outcome != tt.wantOutcome {
				t.Errorf("Expected outcome %s, got %s", tt.wantOutcome, gameState.Outcome)
			}

			// Verify turn (only if move was valid)
			if !tt.wantError {
				if gameState.Outcome == "ongoing" && gameState.CurrentTurn != tt.wantTurn {
					t.Errorf("Expected current turn %s, got %s", tt.wantTurn, gameState.CurrentTurn)
				}

				// Verify timer reset in timer mode
				if gameState.GameMode == "timer" && gameState.Outcome == "ongoing" {
					if gameState.TimerStartTime == nil {
						t.Error("Expected timer to be reset, but it was nil")
					}
				}
			}
		})
	}
}

// TestMatchSignalInvalidData verifies that matchSignal handles invalid signal data
func TestMatchSignalInvalidData(t *testing.T) {
	match := &TicTacToeMatch{}
	ctx := context.Background()

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

	tests := []struct {
		name       string
		signalData string
		wantError  bool
	}{
		{
			name:       "Invalid JSON",
			signalData: "{invalid json}",
			wantError:  true,
		},
		{
			name:       "Missing type field",
			signalData: `{"row": 0, "col": 0, "userId": "user1"}`,
			wantError:  true,
		},
		{
			name:       "Unknown signal type",
			signalData: `{"type": "unknown", "row": 0, "col": 0, "userId": "user1"}`,
			wantError:  true,
		},
		{
			name:       "Missing row field",
			signalData: `{"type": "move", "col": 0, "userId": "user1"}`,
			wantError:  true,
		},
		{
			name:       "Missing col field",
			signalData: `{"type": "move", "row": 0, "userId": "user1"}`,
			wantError:  true,
		},
		{
			name:       "Missing userId field",
			signalData: `{"type": "move", "row": 0, "col": 0}`,
			wantError:  true,
		},
		{
			name:       "Unknown user",
			signalData: `{"type": "move", "row": 0, "col": 0, "userId": "unknown"}`,
			wantError:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			dispatcher := &mockDispatcher{}
			_, errMsg := match.MatchSignal(ctx, &mockLogger{}, nil, nil, dispatcher, 0, state, tt.signalData)

			if tt.wantError && errMsg == "" {
				t.Error("Expected error message, got empty string")
			}
		})
	}
}
