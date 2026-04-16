package main

import (
	"testing"

	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/gen"
	"github.com/leanovate/gopter/prop"
)

// Feature: multiplayer-tictactoe-nakama, Property 3: Move validation rejects invalid moves
// **Validates: Requirements 3.2, 3.3, 3.4**
func TestProperty_MoveValidationRejectsInvalidMoves(t *testing.T) {
	properties := gopter.NewProperties(nil)

	properties.Property("Invalid turn is rejected", prop.ForAll(
		func(currentTurn string, wrongSymbol string) bool {
			state := createOngoingGameState(currentTurn)
			
			// Ensure wrongSymbol is different from currentTurn
			if wrongSymbol == currentTurn {
				if currentTurn == "X" {
					wrongSymbol = "O"
				} else {
					wrongSymbol = "X"
				}
			}
			
			err := ValidateMove(state, wrongSymbol, 0, 0)
			return err != nil && err.Code == ErrorInvalidTurn
		},
		genSymbol(),
		genSymbol(),
	))

	properties.Property("Occupied position is rejected", prop.ForAll(
		func(row, col int, symbol string) bool {
			state := createOngoingGameState(symbol)
			// Occupy the position
			state.Board[row][col] = "X"
			
			err := ValidateMove(state, symbol, row, col)
			return err != nil && err.Code == ErrorPositionOccupied
		},
		gen.IntRange(0, 2),
		gen.IntRange(0, 2),
		genSymbol(),
	))

	properties.Property("Game ended is rejected", prop.ForAll(
		func(outcome string, row, col int, symbol string) bool {
			state := createOngoingGameState(symbol)
			// Set game to ended state
			state.Outcome = outcome
			
			err := ValidateMove(state, symbol, row, col)
			return err != nil && err.Code == ErrorGameEnded
		},
		genGameOutcome(),
		gen.IntRange(0, 2),
		gen.IntRange(0, 2),
		genSymbol(),
	))

	properties.Property("Invalid position coordinates are rejected", prop.ForAll(
		func(row, col int, symbol string) bool {
			state := createOngoingGameState(symbol)
			
			err := ValidateMove(state, symbol, row, col)
			return err != nil && err.Code == ErrorInvalidPosition
		},
		genInvalidCoordinate(),
		genInvalidCoordinate(),
		genSymbol(),
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// Feature: multiplayer-tictactoe-nakama, Property 4: Invalid moves produce error messages
// **Validates: Requirements 3.5**
func TestProperty_InvalidMovesProduceErrorMessages(t *testing.T) {
	properties := gopter.NewProperties(nil)

	properties.Property("All invalid moves return error messages", prop.ForAll(
		func(invalidMoveType int, row, col int) bool {
			state := createOngoingGameState("X")
			var err *ValidationError
			
			// Ensure row and col are in valid range for cases that need them
			validRow := abs(row) % 3
			validCol := abs(col) % 3
			
			switch invalidMoveType % 4 {
			case 0: // Invalid turn
				err = ValidateMove(state, "O", validRow, validCol)
			case 1: // Occupied position
				state.Board[validRow][validCol] = "X"
				err = ValidateMove(state, "X", validRow, validCol)
			case 2: // Game ended
				state.Outcome = "player1_wins"
				err = ValidateMove(state, "X", validRow, validCol)
			case 3: // Invalid position
				invalidRow := row
				if invalidRow >= 0 && invalidRow <= 2 {
					invalidRow = 10 // Make it invalid
				}
				err = ValidateMove(state, "X", invalidRow, validCol)
			}
			
			return err != nil && err.Message != ""
		},
		gen.IntRange(0, 100),
		gen.IntRange(-5, 10),
		gen.IntRange(-5, 10),
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// Helper functions for test data generation

func createOngoingGameState(currentTurn string) *GameState {
	return &GameState{
		Board: [][]string{
			{"", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn: currentTurn,
		Player1: PlayerInfo{
			UserID:   "player1",
			Username: "Player 1",
			Symbol:   "X",
		},
		Player2: PlayerInfo{
			UserID:   "player2",
			Username: "Player 2",
			Symbol:   "O",
		},
		Outcome:  "ongoing",
		GameMode: "classic",
	}
}

func genSymbol() gopter.Gen {
	return gen.OneConstOf("X", "O")
}

func genGameOutcome() gopter.Gen {
	return gen.OneConstOf("player1_wins", "player2_wins", "draw")
}

func genInvalidCoordinate() gopter.Gen {
	return gen.OneGenOf(
		gen.IntRange(-10, -1),
		gen.IntRange(3, 10),
	)
}

// Helper function to get absolute value
func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}
