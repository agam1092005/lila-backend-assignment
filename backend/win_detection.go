package main

// CheckWinCondition checks the board for win or draw conditions
// Returns the game outcome: "player1_wins", "player2_wins", "draw", or "ongoing"
func CheckWinCondition(state *GameState) string {
	board := state.Board

	// Check all three rows for matching symbols
	for row := 0; row < 3; row++ {
		if board[row][0] != "" && board[row][0] == board[row][1] && board[row][1] == board[row][2] {
			return getOutcomeForSymbol(state, board[row][0])
		}
	}

	// Check all three columns for matching symbols
	for col := 0; col < 3; col++ {
		if board[0][col] != "" && board[0][col] == board[1][col] && board[1][col] == board[2][col] {
			return getOutcomeForSymbol(state, board[0][col])
		}
	}

	// Check both diagonals for matching symbols
	// Top-left to bottom-right diagonal
	if board[0][0] != "" && board[0][0] == board[1][1] && board[1][1] == board[2][2] {
		return getOutcomeForSymbol(state, board[0][0])
	}

	// Top-right to bottom-left diagonal
	if board[0][2] != "" && board[0][2] == board[1][1] && board[1][1] == board[2][0] {
		return getOutcomeForSymbol(state, board[0][2])
	}

	// Check for draw condition: board full with no winner
	boardFull := true
	for row := 0; row < 3; row++ {
		for col := 0; col < 3; col++ {
			if board[row][col] == "" {
				boardFull = false
				break
			}
		}
		if !boardFull {
			break
		}
	}

	if boardFull {
		return "draw"
	}

	// Game is still ongoing
	return "ongoing"
}

// getOutcomeForSymbol returns the appropriate outcome based on which player has the winning symbol
func getOutcomeForSymbol(state *GameState, symbol string) string {
	if state.Player1.Symbol == symbol {
		return "player1_wins"
	}
	return "player2_wins"
}
