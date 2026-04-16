package main

import (
	"context"
	"testing"

	"github.com/heroiclabs/nakama-common/runtime"
)

// MockMatchmakerEntry implements runtime.MatchmakerEntry for testing
type MockMatchmakerEntry struct {
	presence   runtime.Presence
	properties map[string]interface{}
}

func (m *MockMatchmakerEntry) GetPresence() runtime.Presence {
	return m.presence
}

func (m *MockMatchmakerEntry) GetProperties() map[string]interface{} {
	return m.properties
}

func (m *MockMatchmakerEntry) GetTicket() string {
	return "test-ticket"
}

func (m *MockMatchmakerEntry) GetPartyId() string {
	return ""
}

func (m *MockMatchmakerEntry) GetCreateTime() int64 {
	return 0
}

// MockPresence implements runtime.Presence for testing
type MockPresence struct {
	userID   string
	username string
}

func (m *MockPresence) GetUserId() string {
	return m.userID
}

func (m *MockPresence) GetSessionId() string {
	return "session-" + m.userID
}

func (m *MockPresence) GetNodeId() string {
	return "node-1"
}

func (m *MockPresence) GetHidden() bool {
	return false
}

func (m *MockPresence) GetPersistence() bool {
	return true
}

func (m *MockPresence) GetUsername() string {
	return m.username
}

func (m *MockPresence) GetStatus() string {
	return "online"
}

func (m *MockPresence) GetReason() runtime.PresenceReason {
	return runtime.PresenceReasonUnknown
}

// mockLogger implements runtime.Logger for testing
type mockMatchmakingLogger struct{}

func (m *mockMatchmakingLogger) Debug(format string, v ...interface{}) {}
func (m *mockMatchmakingLogger) Info(format string, v ...interface{})  {}
func (m *mockMatchmakingLogger) Warn(format string, v ...interface{})  {}
func (m *mockMatchmakingLogger) Error(format string, v ...interface{}) {}
func (m *mockMatchmakingLogger) WithField(key string, v interface{}) runtime.Logger {
	return m
}
func (m *mockMatchmakingLogger) WithFields(fields map[string]interface{}) runtime.Logger {
	return m
}
func (m *mockMatchmakingLogger) Fields() map[string]interface{} {
	return nil
}

// TestMatchmakerMatchedHandler_InvalidPlayerCount tests error handling for wrong number of players
func TestMatchmakerMatchedHandler_InvalidPlayerCount(t *testing.T) {
	ctx := context.Background()
	logger := &mockMatchmakingLogger{}

	// Create only one player (should fail)
	entries := []runtime.MatchmakerEntry{
		&MockMatchmakerEntry{
			presence: &MockPresence{
				userID:   "player1",
				username: "Player One",
			},
			properties: map[string]interface{}{
				"game_mode": "classic",
			},
		},
	}

	_, err := MatchmakerMatchedHandler(ctx, logger, nil, nil, entries)

	if err == nil {
		t.Fatal("Expected error for invalid player count, got nil")
	}
}

// TestMatchmakerMatchedHandler_ThreePlayers tests error handling for three players
func TestMatchmakerMatchedHandler_ThreePlayers(t *testing.T) {
	ctx := context.Background()
	logger := &mockMatchmakingLogger{}

	// Create three players (should fail - we only support 2 players)
	entries := []runtime.MatchmakerEntry{
		&MockMatchmakerEntry{
			presence: &MockPresence{
				userID:   "player1",
				username: "Player One",
			},
			properties: map[string]interface{}{
				"game_mode": "classic",
			},
		},
		&MockMatchmakerEntry{
			presence: &MockPresence{
				userID:   "player2",
				username: "Player Two",
			},
			properties: map[string]interface{}{
				"game_mode": "classic",
			},
		},
		&MockMatchmakerEntry{
			presence: &MockPresence{
				userID:   "player3",
				username: "Player Three",
			},
			properties: map[string]interface{}{
				"game_mode": "classic",
			},
		},
	}

	_, err := MatchmakerMatchedHandler(ctx, logger, nil, nil, entries)

	if err == nil {
		t.Fatal("Expected error for invalid player count (3 players), got nil")
	}
}

