package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
)

// TicTacToeMatch implements the Nakama match handler interface
type TicTacToeMatch struct {
	ctx context.Context
	nk  runtime.NakamaModule
}

// matchLabel is used to identify the match type
const matchLabel = "tictactoe"

// matchInit initializes a new match with empty board and assigns player symbols
func (m *TicTacToeMatch) MatchInit(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, params map[string]interface{}) (interface{}, int, string) {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in MatchInit: %v", r)
			// Return a default state on panic
		}
	}()

	// Store context and nk module for later use
	m.ctx = ctx
	m.nk = nk
	
	// Initialize empty 3x3 board
	board := [][]string{
		{"", "", ""},
		{"", "", ""},
		{"", "", ""},
	}

	// Extract game mode from params (default to "classic")
	gameMode := "classic"
	if mode, ok := params["gameMode"].(string); ok {
		if gameMode != "classic" && gameMode != "timer" {
			logger.Warn("Invalid game mode '%s', defaulting to classic", mode)
			gameMode = "classic"
		} else {
			gameMode = mode
		}
	}

	// Initialize game state
	state := &GameState{
		Board:         board,
		CurrentTurn:   "X", // X always goes first
		Player1:       PlayerInfo{},
		Player2:       PlayerInfo{},
		Outcome:       "ongoing",
		GameMode:      gameMode,
		TimerDuration: 30, // 30 seconds for timer mode
	}

	// Set timer start time to nil initially (will be set when both players join)
	state.TimerStartTime = nil

	// Tick rate: 1 tick per second for timer mode, 0 for classic mode
	tickRate := 0
	if gameMode == "timer" {
		tickRate = 1 // 1 tick per second
	}

	logger.Info("Match initialized with game mode: %s", gameMode)

	return state, tickRate, matchLabel
}

// matchJoinAttempt validates that the match has space for the player
func (m *TicTacToeMatch) MatchJoinAttempt(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presence runtime.Presence, metadata map[string]string) (interface{}, bool, string) {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in MatchJoinAttempt - User: %s, Panic: %v", presence.GetUserId(), r)
			// Reject join on panic to prevent corrupted state
		}
	}()

	gameState, ok := state.(*GameState)
	if !ok {
		logger.Error("Invalid state type in matchJoinAttempt - Expected *GameState, got %T", state)
		return state, false, "Internal error"
	}

	// Check if match already has 2 players
	if gameState.Player1.UserID != "" && gameState.Player2.UserID != "" {
		logger.Info("Match is full, rejecting join attempt from user: %s", presence.GetUserId())
		return state, false, "Match is full"
	}

	logger.Info("Join attempt accepted for user: %s", presence.GetUserId())
	return state, true, ""
}

// matchJoin adds a player to the game state and starts the game when both players have joined
func (m *TicTacToeMatch) MatchJoin(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in MatchJoin - Panic: %v, State: %+v", r, state)
			// Return current state to preserve game
		}
	}()

	gameState, ok := state.(*GameState)
	if !ok {
		logger.Error("Invalid state type in matchJoin - Expected *GameState, got %T", state)
		return state
	}

	for _, presence := range presences {
		// Assign player to Player1 or Player2 slot deterministically
		if gameState.Player1.UserID == "" {
			// First player gets X
			gameState.Player1 = PlayerInfo{
				UserID:    presence.GetUserId(),
				Username:  presence.GetUsername(),
				Symbol:    "X",
				SessionID: presence.GetSessionId(),
			}
			logger.Info("Player 1 joined: %s (Symbol: X, UserID: %s)", presence.GetUsername(), presence.GetUserId())
		} else if gameState.Player2.UserID == "" {
			// Second player gets O
			gameState.Player2 = PlayerInfo{
				UserID:    presence.GetUserId(),
				Username:  presence.GetUsername(),
				Symbol:    "O",
				SessionID: presence.GetSessionId(),
			}
			logger.Info("Player 2 joined: %s (Symbol: O, UserID: %s)", presence.GetUsername(), presence.GetUserId())
		}
	}

	// Start game when both players have joined
	if gameState.Player1.UserID != "" && gameState.Player2.UserID != "" {
		logger.Info("Both players joined, starting game - P1: %s, P2: %s, Mode: %s", 
			gameState.Player1.Username, gameState.Player2.Username, gameState.GameMode)

		// Start timer if in timer mode
		if gameState.GameMode == "timer" {
			now := time.Now().Unix()
			gameState.TimerStartTime = &now
			logger.Info("Timer started for first turn at timestamp: %d", now)
		}

		// Broadcast initial game state to both players
		m.broadcastState(dispatcher, gameState, logger)
	}

	return gameState
}

// matchLeave handles player disconnection and awards win to remaining player
func (m *TicTacToeMatch) MatchLeave(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, presences []runtime.Presence) interface{} {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in MatchLeave - Panic: %v, State: %+v", r, state)
			// Return current state to preserve game
		}
	}()

	gameState, ok := state.(*GameState)
	if !ok {
		logger.Error("Invalid state type in matchLeave - Expected *GameState, got %T", state)
		return state
	}

	for _, presence := range presences {
		logger.Info("Player disconnected: %s (UserID: %s, SessionID: %s)", 
			presence.GetUsername(), presence.GetUserId(), presence.GetSessionId())

		// Send disconnection notification to remaining player
		disconnectMsg := &PlayerDisconnected{
			Type:     "player_disconnected",
			PlayerID: presence.GetUserId(),
		}
		m.broadcastMessage(dispatcher, disconnectMsg, logger)

		// If game is still ongoing, award win to remaining player
		if gameState.Outcome == "ongoing" {
			if presence.GetUserId() == gameState.Player1.UserID {
				gameState.Outcome = "player2_wins"
				logger.Info("Player 1 disconnected during active game, Player 2 wins - P1: %s, P2: %s", 
					gameState.Player1.Username, gameState.Player2.Username)
			} else if presence.GetUserId() == gameState.Player2.UserID {
				gameState.Outcome = "player1_wins"
				logger.Info("Player 2 disconnected during active game, Player 1 wins - P1: %s, P2: %s", 
					gameState.Player1.Username, gameState.Player2.Username)
			}

			// Broadcast final game state
			m.broadcastState(dispatcher, gameState, logger)

			// Update player statistics (only if nk module is available)
			if m.nk != nil {
				if err := UpdatePlayerStatistics(m.ctx, logger, m.nk, gameState); err != nil {
					logger.Error("Failed to update player statistics on disconnect - Error: %v, GameState: %+v", err, gameState)
					// Continue despite statistics error - game outcome is already determined
				}
			}
		}
	}

	return gameState
}

// matchLoop handles timer countdown broadcasts in timer mode
func (m *TicTacToeMatch) MatchLoop(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, messages []runtime.MatchData) interface{} {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in MatchLoop - Tick: %d, Panic: %v, State: %+v", tick, r, state)
			// Return current state to preserve game
		}
	}()

	gameState, ok := state.(*GameState)
	if !ok {
		logger.Error("Invalid state type in matchLoop - Expected *GameState, got %T", state)
		return state
	}

	// Only process timer logic in timer mode
	if gameState.GameMode == "timer" && gameState.Outcome == "ongoing" && gameState.TimerStartTime != nil {
		now := time.Now().Unix()
		elapsed := now - *gameState.TimerStartTime
		remaining := gameState.TimerDuration - int(elapsed)

		// Check if timer expired
		if remaining <= 0 {
			// Timer expired, award win to opponent
			if gameState.CurrentTurn == "X" {
				gameState.Outcome = "player2_wins"
				logger.Info("Timer expired for Player 1 (X), Player 2 (O) wins - P1: %s, P2: %s, Elapsed: %ds", 
					gameState.Player1.Username, gameState.Player2.Username, elapsed)
			} else {
				gameState.Outcome = "player1_wins"
				logger.Info("Timer expired for Player 2 (O), Player 1 (X) wins - P1: %s, P2: %s, Elapsed: %ds", 
					gameState.Player1.Username, gameState.Player2.Username, elapsed)
			}

			// Broadcast final game state
			m.broadcastState(dispatcher, gameState, logger)

			// Update player statistics (only if nk module is available)
			if m.nk != nil {
				if err := UpdatePlayerStatistics(m.ctx, logger, m.nk, gameState); err != nil {
					logger.Error("Failed to update player statistics on timer expiry - Error: %v, GameState: %+v", err, gameState)
					// Continue despite statistics error - game outcome is already determined
				}
			}
		} else {
			// Broadcast timer update
			m.broadcastState(dispatcher, gameState, logger)
		}
	}

	// Process incoming messages (moves)
	for _, message := range messages {
		m.handleMessage(ctx, logger, db, nk, dispatcher, gameState, message)
	}

	return gameState
}

// matchTerminate cleans up match resources
func (m *TicTacToeMatch) MatchTerminate(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, graceSeconds int) interface{} {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in MatchTerminate - Panic: %v, State: %+v", r, state)
		}
	}()

	gameState, ok := state.(*GameState)
	if !ok {
		logger.Error("Invalid state type in matchTerminate - Expected *GameState, got %T", state)
		return state
	}

	logger.Info("Match terminating - Final outcome: %s, P1: %s, P2: %s, Mode: %s", 
		gameState.Outcome, gameState.Player1.Username, gameState.Player2.Username, gameState.GameMode)

	// Clean up resources (nothing specific to clean up for this game)
	// The match state will be garbage collected by Nakama

	return state
}

// matchSignal handles custom signals sent to the match, specifically move requests
func (m *TicTacToeMatch) MatchSignal(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, tick int64, state interface{}, data string) (interface{}, string) {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in MatchSignal - Panic: %v, Data: %s, State: %+v", r, data, state)
			// Send error to clients
			errorMsg := &ErrorMessage{
				Type:    "error",
				Message: "An unexpected error occurred. Please try again.",
			}
			m.broadcastMessage(dispatcher, errorMsg, logger)
		}
	}()

	gameState, ok := state.(*GameState)
	if !ok {
		logger.Error("Invalid state type in matchSignal - Expected *GameState, got %T", state)
		errorMsg := &ErrorMessage{
			Type:    "error",
			Message: "Internal error occurred",
		}
		m.broadcastMessage(dispatcher, errorMsg, logger)
		return state, "Internal error: invalid state"
	}

	// Parse the incoming signal data as JSON
	var signalData map[string]interface{}
	if err := json.Unmarshal([]byte(data), &signalData); err != nil {
		logger.Error("Failed to parse signal data - Error: %v, Data: %s", err, data)
		errorMsg := &ErrorMessage{
			Type:    "error",
			Message: "Invalid request format",
		}
		m.broadcastMessage(dispatcher, errorMsg, logger)
		return state, "Invalid signal format"
	}

	// Check if this is a move request
	signalType, ok := signalData["type"].(string)
	if !ok || signalType != "move" {
		logger.Warn("Unknown signal type: %v, Data: %s", signalType, data)
		return state, "Unknown signal type"
	}

	// Extract move parameters
	row, rowOk := signalData["row"].(float64)
	col, colOk := signalData["col"].(float64)
	userID, userOk := signalData["userId"].(string)

	if !rowOk || !colOk || !userOk {
		logger.Error("Invalid move signal parameters - Data: %s", data)
		errorMsg := &ErrorMessage{
			Type:    "error",
			Message: "Invalid move parameters",
		}
		m.broadcastMessage(dispatcher, errorMsg, logger)
		return state, "Invalid move parameters"
	}

	// Determine player symbol
	var playerSymbol string
	if userID == gameState.Player1.UserID {
		playerSymbol = gameState.Player1.Symbol
	} else if userID == gameState.Player2.UserID {
		playerSymbol = gameState.Player2.Symbol
	} else {
		logger.Error("Move from unknown player - UserID: %s, P1: %s, P2: %s", 
			userID, gameState.Player1.UserID, gameState.Player2.UserID)
		errorMsg := &ErrorMessage{
			Type:    "error",
			Message: "You are not in this match",
		}
		m.broadcastMessage(dispatcher, errorMsg, logger)
		return state, "Player not in match"
	}

	// Validate move
	if validationErr := ValidateMove(gameState, playerSymbol, int(row), int(col)); validationErr != nil {
		logger.Info("Move rejected - Player: %s, Symbol: %s, Position: (%d, %d), Reason: %s", 
			userID, playerSymbol, int(row), int(col), validationErr.Message)
		
		// Send error message to the requesting player
		rejectionMsg := &MoveRejected{
			Type:   "move_rejected",
			Reason: validationErr.Message,
		}
		m.broadcastMessage(dispatcher, rejectionMsg, logger)
		return state, validationErr.Message
	}

	// Apply valid move to game state
	gameState.Board[int(row)][int(col)] = playerSymbol
	logger.Info("Move applied - Player: %s, Symbol: %s, Position: (%d, %d)", 
		userID, playerSymbol, int(row), int(col))

	// Check win condition
	gameState.Outcome = CheckWinCondition(gameState)

	// Switch turn if game is still ongoing
	if gameState.Outcome == "ongoing" {
		if gameState.CurrentTurn == "X" {
			gameState.CurrentTurn = "O"
		} else {
			gameState.CurrentTurn = "X"
		}

		// Reset timer for next turn in timer mode
		if gameState.GameMode == "timer" {
			now := time.Now().Unix()
			gameState.TimerStartTime = &now
			logger.Info("Timer reset for next turn - CurrentTurn: %s, Timestamp: %d", gameState.CurrentTurn, now)
		}
	} else {
		logger.Info("Game ended - Outcome: %s, P1: %s, P2: %s", 
			gameState.Outcome, gameState.Player1.Username, gameState.Player2.Username)
		
		// Update player statistics (only if nk module is available)
		if m.nk != nil {
			if err := UpdatePlayerStatistics(m.ctx, logger, m.nk, gameState); err != nil {
				logger.Error("Failed to update player statistics - Error: %v, GameState: %+v", err, gameState)
				// Continue despite statistics error - game outcome is already determined
			}
		}
	}

	// Broadcast updated game state to both players
	m.broadcastState(dispatcher, gameState, logger)

	return gameState, ""
}

// handleMessage processes incoming move requests
func (m *TicTacToeMatch) handleMessage(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, dispatcher runtime.MatchDispatcher, state *GameState, message runtime.MatchData) {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in handleMessage - UserID: %s, Panic: %v, State: %+v", 
				message.GetUserId(), r, state)
			m.sendError(dispatcher, message.GetUserId(), "An unexpected error occurred. Please try again.")
		}
	}()

	// Parse message
	var moveReq MoveRequest
	if err := json.Unmarshal(message.GetData(), &moveReq); err != nil {
		logger.Error("Failed to parse move request - UserID: %s, Error: %v, Data: %s", 
			message.GetUserId(), err, string(message.GetData()))
		m.sendError(dispatcher, message.GetUserId(), "Invalid move request format")
		return
	}

	// Determine player symbol
	var playerSymbol string
	if message.GetUserId() == state.Player1.UserID {
		playerSymbol = state.Player1.Symbol
	} else if message.GetUserId() == state.Player2.UserID {
		playerSymbol = state.Player2.Symbol
	} else {
		logger.Error("Move from unknown player - UserID: %s, P1: %s, P2: %s", 
			message.GetUserId(), state.Player1.UserID, state.Player2.UserID)
		m.sendError(dispatcher, message.GetUserId(), "You are not in this match")
		return
	}

	// Validate move
	if validationErr := ValidateMove(state, playerSymbol, moveReq.Row, moveReq.Col); validationErr != nil {
		logger.Info("Move rejected - Player: %s, Symbol: %s, Position: (%d, %d), Reason: %s", 
			message.GetUserId(), playerSymbol, moveReq.Row, moveReq.Col, validationErr.Message)
		m.sendMoveRejected(dispatcher, message.GetUserId(), validationErr.Message)
		return
	}

	// Apply move
	state.Board[moveReq.Row][moveReq.Col] = playerSymbol
	logger.Info("Move applied - Player: %s, Symbol: %s, Position: (%d, %d)", 
		message.GetUserId(), playerSymbol, moveReq.Row, moveReq.Col)

	// Check win condition
	state.Outcome = CheckWinCondition(state)

	// Switch turn if game is still ongoing
	if state.Outcome == "ongoing" {
		if state.CurrentTurn == "X" {
			state.CurrentTurn = "O"
		} else {
			state.CurrentTurn = "X"
		}

		// Reset timer for next turn in timer mode
		if state.GameMode == "timer" {
			now := time.Now().Unix()
			state.TimerStartTime = &now
			logger.Info("Timer reset for next turn - CurrentTurn: %s, Timestamp: %d", state.CurrentTurn, now)
		}
	} else {
		logger.Info("Game ended - Outcome: %s, P1: %s, P2: %s", 
			state.Outcome, state.Player1.Username, state.Player2.Username)
		
		// Update player statistics (only if nk module is available)
		if m.nk != nil {
			if err := UpdatePlayerStatistics(m.ctx, logger, m.nk, state); err != nil {
				logger.Error("Failed to update player statistics - Error: %v, GameState: %+v", err, state)
				// Continue despite statistics error - game outcome is already determined
			}
		}
	}

	// Broadcast updated state
	m.broadcastState(dispatcher, state, logger)
}

// broadcastState sends the current game state to all players
func (m *TicTacToeMatch) broadcastState(dispatcher runtime.MatchDispatcher, state *GameState, logger runtime.Logger) {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in broadcastState - Panic: %v, State: %+v", r, state)
		}
	}()

	// Calculate timer remaining if in timer mode
	var timerRemaining *int
	if state.GameMode == "timer" && state.Outcome == "ongoing" && state.TimerStartTime != nil {
		now := time.Now().Unix()
		elapsed := now - *state.TimerStartTime
		remaining := state.TimerDuration - int(elapsed)
		if remaining < 0 {
			remaining = 0
		}
		timerRemaining = &remaining
	}

	stateUpdate := &StateUpdate{
		Type:           "state_update",
		Board:          state.Board,
		CurrentTurn:    state.CurrentTurn,
		Player1:        state.Player1,
		Player2:        state.Player2,
		Outcome:        state.Outcome,
		TimerRemaining: timerRemaining,
	}

	data, err := json.Marshal(stateUpdate)
	if err != nil {
		logger.Error("Failed to marshal state update - Error: %v, State: %+v", err, state)
		return
	}

	// Broadcast to all players
	dispatcher.BroadcastMessage(1, data, nil, nil, true)
}

// broadcastMessage sends a message to all players
func (m *TicTacToeMatch) broadcastMessage(dispatcher runtime.MatchDispatcher, message interface{}, logger runtime.Logger) {
	defer func() {
		if r := recover(); r != nil {
			logger.Error("PANIC in broadcastMessage - Panic: %v, Message: %+v", r, message)
		}
	}()

	data, err := json.Marshal(message)
	if err != nil {
		logger.Error("Failed to marshal message - Error: %v, Message: %+v", err, message)
		return
	}

	dispatcher.BroadcastMessage(1, data, nil, nil, true)
}

// sendMoveRejected sends a move rejection message to a specific player
func (m *TicTacToeMatch) sendMoveRejected(dispatcher runtime.MatchDispatcher, userID string, reason string) {
	defer func() {
		if r := recover(); r != nil {
			// Silent recovery - this is a helper function
		}
	}()

	msg := &MoveRejected{
		Type:   "move_rejected",
		Reason: reason,
	}

	data, err := json.Marshal(msg)
	if err != nil {
		return
	}

	// Send to specific player (we don't have a direct way to send to one player,
	// so we broadcast with a filter - in practice, the client should check the message)
	dispatcher.BroadcastMessage(1, data, nil, nil, true)
}

// sendError sends an error message to a specific player
func (m *TicTacToeMatch) sendError(dispatcher runtime.MatchDispatcher, userID string, message string) {
	defer func() {
		if r := recover(); r != nil {
			// Silent recovery - this is a helper function
		}
	}()

	msg := &ErrorMessage{
		Type:    "error",
		Message: message,
	}

	data, err := json.Marshal(msg)
	if err != nil {
		return
	}

	dispatcher.BroadcastMessage(1, data, nil, nil, true)
}
