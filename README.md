# Multiplayer Tic-Tac-Toe with Nakama

A production-ready multiplayer Tic-Tac-Toe game built with Flutter (frontend) and Nakama (backend). Features real-time gameplay, matchmaking, leaderboards, and timer-based game modes.

## 🎮 Live Demo

- **Frontend**: [Your Vercel URL - Add after deployment]
- **Nakama Server**: [Your Oracle Cloud IP - Add after deployment]

## 📋 Features

- ✅ Real-time multiplayer gameplay
- ✅ Server-authoritative game logic (prevents cheating)
- ✅ Automatic matchmaking system
- ✅ Global leaderboard with player statistics
- ✅ Two game modes: Classic and Timer (30s per turn)
- ✅ Cross-platform support (Web, Android, iOS)
- ✅ Light Blue and Dark Blue themes
- ✅ Responsive design for mobile and desktop
- ✅ Player disconnection handling
- ✅ Win streak tracking

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────┐
│  Flutter Web    │
│  (Frontend)     │◄──── WebSocket/HTTPS ────┐
└─────────────────┘                          │
                                             │
┌─────────────────┐                          │
│ Flutter Android │                          │
│  (Frontend)     │◄──── WebSocket/HTTPS ────┤
└─────────────────┘                          │
                                             │
┌─────────────────┐                          │
│  Flutter iOS    │                          │
│  (Frontend)     │◄──── WebSocket/HTTPS ────┤
└─────────────────┘                          │
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │  Nakama Server  │
                                    │  (Go Runtime)   │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │   PostgreSQL    │
                                    │   (Database)    │
                                    └─────────────────┘
```

### Technology Stack

**Frontend:**
- Flutter 3.x (Dart)
- nakama package for server communication
- shared_preferences for local storage
- Responsive UI with Material Design

**Backend:**
- Nakama 3.17.1 (Game server)
- Go 1.20 (Custom runtime modules)
- PostgreSQL 12 (Database)
- Docker & Docker Compose (Containerization)

### Design Decisions

1. **Server-Authoritative Architecture**
   - All game logic executes on the server
   - Clients only send move intentions, not state changes
   - Prevents client-side cheating and manipulation
   - Single source of truth for game state

2. **Real-Time Communication**
   - WebSocket for low-latency game updates
   - Server broadcasts state changes to all players
   - Automatic reconnection handling

3. **Matchmaking System**
   - Queue-based matchmaking
   - Filters by game mode (classic/timer)
   - Automatic pairing when two players available

4. **Statistics & Leaderboard**
   - Persistent player statistics (wins, losses, streaks)
   - Global leaderboard sorted by wins
   - Automatic updates after each game

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Flutter SDK 3.0+
- Go 1.20+ (for backend development)
- Git

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd multiplayer-tictactoe-nakama
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start the backend (Nakama + PostgreSQL)**
   ```bash
   docker-compose up -d
   ```

4. **Verify backend is running**
   ```bash
   curl http://localhost:7351/
   # Should return Nakama health check response
   ```

5. **Run the Flutter app**
   ```bash
   cd frontend
   flutter pub get
   flutter run -d chrome  # For web
   # OR
   flutter run -d android # For Android
   # OR
   flutter run -d ios     # For iOS
   ```

### Building the Backend Plugin (Mac Users)

If you're on macOS and need to rebuild the backend plugin:

```bash
# Build for Linux (required for Docker)
./build-backend-linux.sh

# Restart Nakama to load the new plugin
docker-compose restart nakama
```

## 🧪 Testing the Multiplayer Functionality

### Test Scenario 1: Basic Matchmaking and Gameplay

1. Open the app in your browser: `http://localhost:PORT`
2. Click "Find Match" → Select "Classic Mode"
3. Open a second browser window (or incognito mode)
4. Click "Find Match" → Select "Classic Mode"
5. Both players should be matched and see the game board
6. Take turns making moves
7. Verify win detection and game outcome display

### Test Scenario 2: Timer Mode

1. Start matchmaking with "Timer Mode" in both windows
2. Observe the 30-second countdown timer
3. Let the timer expire without making a move
4. Verify the opponent wins automatically

### Test Scenario 3: Disconnection Handling

1. Start a game between two players
2. Close one browser window
3. Verify the remaining player receives a win after ~10 seconds

### Test Scenario 4: Leaderboard

1. Complete several games
2. Navigate to the Leaderboard screen
3. Verify player statistics are displayed correctly
4. Check wins, losses, and win streaks

### Test Scenario 5: Theme Switching

1. Click the theme toggle button
2. Verify the theme switches between Light Blue and Dark Blue
3. Refresh the page
4. Verify the theme preference persists

## 📦 Project Structure

```
.
├── backend/                    # Nakama Go runtime modules
│   ├── main.go                # Entry point and initialization
│   ├── match_handler.go       # Match lifecycle and game logic
│   ├── matchmaking.go         # Matchmaking RPC
│   ├── leaderboard_rpc.go     # Leaderboard queries
│   ├── statistics.go          # Player statistics tracking
│   ├── validation.go          # Move validation logic
│   ├── win_detection.go       # Win/draw detection
│   ├── types.go               # Data structures
│   └── *_test.go              # Unit and property tests
│
├── frontend/                   # Flutter application
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── screens/           # UI screens
│   │   ├── services/          # Business logic
│   │   ├── widgets/           # Reusable UI components
│   │   └── models/            # Data models
│   ├── web/                   # Web-specific files
│   ├── android/               # Android-specific files
│   └── ios/                   # iOS-specific files
│
├── docker-compose.yml         # Local development environment
├── docker-compose.prod.yml    # Production deployment config
├── .env.example               # Environment variables template
├── build-backend-linux.sh     # Cross-compilation script
├── README.md                  # This file
└── DEPLOYMENT.md              # Production deployment guide
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file with the following variables:

```env
# Database
DB_PASSWORD=your_secure_password

# Nakama
SESSION_KEY=your_random_session_key

# Frontend (for production builds)
NAKAMA_SERVER_URL=http://localhost:7351
```

### Nakama Configuration

The Nakama server is configured via command-line flags in `docker-compose.yml`:

- **Database**: PostgreSQL connection string
- **Session expiry**: 7200 seconds (2 hours)
- **Logger level**: INFO
- **Runtime path**: `/nakama/data/modules` (Go plugins)

## 🌐 API/Server Configuration

### Nakama Endpoints

- **HTTP API**: `http://localhost:7351`
- **gRPC API**: `http://localhost:7350`
- **Console**: `http://localhost:7351` (admin/password)

### Custom RPCs

1. **Matchmaking RPC**
   - **ID**: `matchmaking`
   - **Payload**: `{ "gameMode": "classic" | "timer" }`
   - **Returns**: Match ID when paired

2. **Leaderboard RPC**
   - **ID**: `get_leaderboard`
   - **Payload**: `{}`
   - **Returns**: Top 10 players with stats

### Match Signals

- **Move Signal**: `{ "type": "move", "row": 0-2, "col": 0-2 }`
- **State Update**: Broadcast to all players on state change

## 📊 Database Schema

### Player Statistics (Nakama Storage)

```json
{
  "collection": "player_stats",
  "key": "{userId}",
  "value": {
    "userId": "string",
    "wins": "number",
    "losses": "number",
    "winStreak": "number",
    "lastUpdated": "timestamp"
  }
}
```

### Leaderboard

- **ID**: `global_leaderboard`
- **Score**: Wins count
- **Subscore**: Win streak
- **Sort**: Descending by score

## 🐛 Troubleshooting

### Backend won't start

```bash
# Check logs
docker-compose logs nakama

# Common issues:
# 1. PostgreSQL not ready - wait for health check
# 2. Port already in use - change ports in docker-compose.yml
# 3. Plugin loading error - rebuild with ./build-backend-linux.sh
```

### Frontend can't connect

```bash
# Verify Nakama is running
curl http://localhost:7351/

# Check NAKAMA_SERVER_URL in your Flutter app
# For local development: http://localhost:7351
# For production: https://your-server.com:7351
```

### Plugin loading errors (Mac users)

The backend plugin must be built for Linux. Use the provided script:

```bash
./build-backend-linux.sh
docker-compose restart nakama
```

## 📝 Development Notes

### Running Tests

**Backend tests:**
```bash
cd backend
go test ./... -v
```

**Frontend tests:**
```bash
cd frontend
flutter test
```

### Code Style

- **Go**: Follow standard Go conventions, use `gofmt`
- **Dart**: Follow Flutter style guide, use `dart format`

## 📄 License

[Your License Here]

## 👥 Contributors

[Your Name/Team]

## 📞 Support

For issues or questions, please open an issue in the repository.
