package main

import (
	"testing"

	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/gen"
	"github.com/leanovate/gopter/prop"
)

// Feature: multiplayer-tictactoe-nakama, Property 7: Win detection identifies all winning conditions
// **Validates: Requirements 5.1, 5.2, 5.3**
func TestProperty_WinDetectionIdentifiesAllWinningConditions(t *testing.T) {
	properties := gopter.NewProperties(nil)

	// Test row wins
	properties.Property("Row wins are detected correctly", prop.ForAll(
		func(rowIndex int, symbol string) bool {
			state := createGameStateWithPlayers(symbol)
			// Fill the specified row with the symbol
			for col := 0; col < 3; col++ {
				state.Board[rowIndex][col] = symbol
			}
			
			outcome := CheckWinCondition(state)
			expectedOutcome := getOutcomeForSymbol(state, symbol)
			return outcome == expectedOutcome
		},
		gen.IntRange(0, 2),
		genSymbol(),
	))

	// Test column wins
	properties.Property("Column wins are detected correctly", prop.ForAll(
		func(colIndex int, symbol string) bool {
			state := createGameStateWithPlayers(symbol)
			// Fill the specified column with the symbol
			for row := 0; row < 3; row++ {
				state.Board[row][colIndex] = symbol
			}
			
			outcome := CheckWinCondition(state)
			expectedOutcome := getOutcomeForSymbol(state, symbol)
			return outcome == expectedOutcome
		},
		gen.IntRange(0, 2),
		genSymbol(),
	))

	// Test diagonal wins (top-left to bottom-right)
	properties.Property("Top-left to bottom-right diagonal wins are detected", prop.ForAll(
		func(symbol string) bool {
			state := createGameStateWithPlayers(symbol)
			// Fill the main diagonal
			state.Board[0][0] = symbol
			state.Board[1][1] = symbol
			state.Board[2][2] = symbol
			
			outcome := CheckWinCondition(state)
			expectedOutcome := getOutcomeForSymbol(state, symbol)
			return outcome == expectedOutcome
		},
		genSymbol(),
	))

	// Test diagonal wins (top-right to bottom-left)
	properties.Property("Top-right to bottom-left diagonal wins are detected", prop.ForAll(
		func(symbol string) bool {
			state := createGameStateWithPlayers(symbol)
			// Fill the anti-diagonal
			state.Board[0][2] = symbol
			state.Board[1][1] = symbol
			state.Board[2][0] = symbol
			
			outcome := CheckWinCondition(state)
			expectedOutcome := getOutcomeForSymbol(state, symbol)
			return outcome == expectedOutcome
		},
		genSymbol(),
	))

	// Test that winning player is correctly identified
	properties.Property("Winning player is correctly identified", prop.ForAll(
		func(winType int, player1Symbol string) bool {
			// Determine player symbols
			player2Symbol := "O"
			if player1Symbol == "O" {
				player2Symbol = "X"
			}
			
			state := &GameState{
				Board: [][]string{
					{"", "", ""},
					{"", "", ""},
					{"", "", ""},
				},
				CurrentTurn: player1Symbol,
				Player1: PlayerInfo{
					UserID:   "player1",
					Username: "Player 1",
					Symbol:   player1Symbol,
				},
				Player2: PlayerInfo{
					UserID:   "player2",
					Username: "Player 2",
					Symbol:   player2Symbol,
				},
				Outcome:  "ongoing",
				GameMode: "classic",
			}
			
			// Create a win for player1
			switch winType % 3 {
			case 0: // Row win
				state.Board[0][0] = player1Symbol
				state.Board[0][1] = player1Symbol
				state.Board[0][2] = player1Symbol
			case 1: // Column win
				state.Board[0][0] = player1Symbol
				state.Board[1][0] = player1Symbol
				state.Board[2][0] = player1Symbol
			case 2: // Diagonal win
				state.Board[0][0] = player1Symbol
				state.Board[1][1] = player1Symbol
				state.Board[2][2] = player1Symbol
			}
			
			outcome := CheckWinCondition(state)
			return outcome == "player1_wins"
		},
		gen.IntRange(0, 100),
		genSymbol(),
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// Feature: multiplayer-tictactoe-nakama, Property 8: Draw detection identifies full boards without winners
// **Validates: Requirements 5.4**
func TestProperty_DrawDetectionIdentifiesFullBoardsWithoutWinners(t *testing.T) {
	properties := gopter.NewProperties(nil)

	properties.Property("Full board without winner is detected as draw", prop.ForAll(
		func(seed int) bool {
			state := createGameStateWithPlayers("X")
			
			// Create a draw board configuration
			// Pattern that ensures no wins:
			// X O X
			// X O O
			// O X X
			state.Board = [][]string{
				{"X", "O", "X"},
				{"X", "O", "O"},
				{"O", "X", "X"},
			}
			
			outcome := CheckWinCondition(state)
			return outcome == "draw"
		},
		gen.Int(),
	))

	properties.Property("Partial board is not detected as draw", prop.ForAll(
		func(emptyRow, emptyCol int) bool {
			state := createGameStateWithPlayers("X")
			
			// Fill board completely
			state.Board = [][]string{
				{"X", "O", "X"},
				{"X", "O", "O"},
				{"O", "X", "X"},
			}
			
			// Make one position empty
			state.Board[emptyRow][emptyCol] = ""
			
			outcome := CheckWinCondition(state)
			return outcome == "ongoing"
		},
		gen.IntRange(0, 2),
		gen.IntRange(0, 2),
	))

	properties.Property("Various draw configurations are detected", prop.ForAll(
		func(pattern int) bool {
			state := createGameStateWithPlayers("X")
			
			// Different draw patterns
			switch pattern % 3 {
			case 0:
				// Pattern 1
				state.Board = [][]string{
					{"X", "O", "X"},
					{"O", "X", "O"},
					{"O", "X", "O"},
				}
			case 1:
				// Pattern 2
				state.Board = [][]string{
					{"O", "X", "O"},
					{"X", "X", "O"},
					{"X", "O", "X"},
				}
			case 2:
				// Pattern 3
				state.Board = [][]string{
					{"X", "X", "O"},
					{"O", "O", "X"},
					{"X", "O", "X"},
				}
			}
			
			outcome := CheckWinCondition(state)
			return outcome == "draw"
		},
		gen.IntRange(0, 100),
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// Helper function to create a game state with players
func createGameStateWithPlayers(winningSymbol string) *GameState {
	player1Symbol := "X"
	player2Symbol := "O"
	
	// If winning symbol is O, swap the symbols
	if winningSymbol == "O" {
		player1Symbol = "O"
		player2Symbol = "X"
	}
	
	return &GameState{
		Board: [][]string{
			{"", "", ""},
			{"", "", ""},
			{"", "", ""},
		},
		CurrentTurn: winningSymbol,
		Player1: PlayerInfo{
			UserID:   "player1",
			Username: "Player 1",
			Symbol:   player1Symbol,
		},
		Player2: PlayerInfo{
			UserID:   "player2",
			Username: "Player 2",
			Symbol:   player2Symbol,
		},
		Outcome:  "ongoing",
		GameMode: "classic",
	}
}
