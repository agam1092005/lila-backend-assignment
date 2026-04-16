package main

// GameState represents the complete state of a Tic-Tac-Toe game
type GameState struct {
	Board          [][]string  `json:"board"`          // 3x3 array, values: "", "X", "O"
	CurrentTurn    string      `json:"currentTurn"`    // "X" or "O"
	Player1        PlayerInfo  `json:"player1"`
	Player2        PlayerInfo  `json:"player2"`
	Outcome        string      `json:"outcome"`        // "ongoing", "player1_wins", "player2_wins", "draw"
	GameMode       string      `json:"gameMode"`       // "classic" or "timer"
	TimerStartTime *int64      `json:"timerStartTime"` // Unix timestamp, timer mode only
	TimerDuration  int         `json:"timerDuration"`  // seconds, 30 for timer mode
}

// PlayerInfo represents information about a player in a game
type PlayerInfo struct {
	UserID    string `json:"userId"`
	Username  string `json:"username"`
	Symbol    string `json:"symbol"`    // "X" or "O"
	SessionID string `json:"sessionId"`
}

// Message protocol types for client-server communication

// MatchmakingRequest is sent by the client to request matchmaking
type MatchmakingRequest struct {
	Type     string `json:"type"`     // "matchmaking_request"
	GameMode string `json:"gameMode"` // "classic" or "timer"
}

// MoveRequest is sent by the client to make a move
type MoveRequest struct {
	Type string `json:"type"` // "move"
	Row  int    `json:"row"`  // 0-2
	Col  int    `json:"col"`  // 0-2
}

// StateUpdate is sent by the server to update game state
type StateUpdate struct {
	Type           string      `json:"type"`           // "state_update"
	Board          [][]string  `json:"board"`          // 3x3 array, values: "", "X", "O"
	CurrentTurn    string      `json:"currentTurn"`    // "X" or "O"
	Player1        PlayerInfo  `json:"player1"`
	Player2        PlayerInfo  `json:"player2"`
	Outcome        string      `json:"outcome"`        // "ongoing", "player1_wins", "player2_wins", "draw"
	TimerRemaining *int        `json:"timerRemaining"` // seconds, only in timer mode
}

// MoveRejected is sent by the server when a move is invalid
type MoveRejected struct {
	Type   string `json:"type"`   // "move_rejected"
	Reason string `json:"reason"`
}

// PlayerDisconnected is sent by the server when a player disconnects
type PlayerDisconnected struct {
	Type     string `json:"type"`     // "player_disconnected"
	PlayerID string `json:"playerId"`
}

// ErrorMessage is sent by the server when an error occurs
type ErrorMessage struct {
	Type    string `json:"type"`    // "error"
	Message string `json:"message"`
}
