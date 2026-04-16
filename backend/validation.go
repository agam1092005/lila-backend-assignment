package main

import "fmt"

// ValidationError represents a move validation error with code and message
type ValidationError struct {
	Code    string
	Message string
}

// Error implements the error interface
func (e *ValidationError) Error() string {
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// Error codes for move validation
const (
	ErrorInvalidTurn     = "INVALID_TURN"
	ErrorPositionOccupied = "POSITION_OCCUPIED"
	ErrorGameEnded       = "GAME_ENDED"
	ErrorInvalidPosition = "INVALID_POSITION"
)

// ValidateMove validates a move request against the current game state
// Returns nil if the move is valid, or a ValidationError if invalid
func ValidateMove(state *GameState, playerSymbol string, row, col int) *ValidationError {
	// Validate game status: game outcome must be "ongoing"
	if state.Outcome != "ongoing" {
		return &ValidationError{
			Code:    ErrorGameEnded,
			Message: "Game has already ended",
		}
	}

	// Validate board position: coordinates must be 0-2
	if row < 0 || row > 2 || col < 0 || col > 2 {
		return &ValidationError{
			Code:    ErrorInvalidPosition,
			Message: fmt.Sprintf("Invalid position: row=%d, col=%d (must be 0-2)", row, col),
		}
	}

	// Validate turn order: move must be from player whose turn it is
	if state.CurrentTurn != playerSymbol {
		return &ValidationError{
			Code:    ErrorInvalidTurn,
			Message: fmt.Sprintf("Not your turn (current turn: %s, your symbol: %s)", state.CurrentTurn, playerSymbol),
		}
	}

	// Validate board position: target cell must be empty
	if state.Board[row][col] != "" {
		return &ValidationError{
			Code:    ErrorPositionOccupied,
			Message: fmt.Sprintf("Position already occupied at row=%d, col=%d", row, col),
		}
	}

	return nil
}
