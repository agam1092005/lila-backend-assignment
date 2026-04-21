# Multiplayer Tic-Tac-Toe with Nakama

A production-ready multiplayer Tic-Tac-Toe game built with Flutter (frontend) and Nakama (backend). Features real-time gameplay, matchmaking, leaderboards, and timer-based game modes.

## 🎮 Live Deployment

- **Frontend**: `http://152.67.10.16:7351`
- **Backend (Nakama)**: `http://152.67.10.16:7350`
- **WebSocket**: `ws://152.67.10.16:7350`

## 📋 Features

- Real-time multiplayer gameplay
- Server-authoritative game logic (prevents cheating)
- Automatic matchmaking system
- Global leaderboard with player statistics
- Two game modes: Classic and Timer (30s per turn)
- Cross-platform support (Web, Android, iOS)
- Player disconnection handling
- Win streak tracking

## 🏗️ Architecture & Design Decisions

### System Architecture

```
Flutter Frontend (Web/Android/iOS)
         ↓ WebSocket
    Nakama Server (Go Runtime)
         ↓
    PostgreSQL Database
```

### Technology Stack

**Frontend:** Flutter 3.x (Dart), nakama package, Material Design
**Backend:** Nakama 3.17.1, Go 1.20 runtime modules, PostgreSQL 12
**Infrastructure:** Docker & Docker Compose

### Key Design Decisions

1. **Server-Authoritative Architecture** - All game logic on server, clients only send moves. Prevents cheating and maintains single source of truth.

2. **Real-Time Communication** - WebSocket for low-latency updates with automatic reconnection handling.

3. **Queue-Based Matchmaking** - Filters by game mode and automatically pairs players.

4. **Persistent Statistics** - Player wins, losses, and streaks tracked in database with global leaderboard.

## 🚀 Setup & Installation

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
   ```

3. **Start the backend**
   ```bash
   docker-compose up -d
   ```

4. **Verify backend is running**
   ```bash
   curl http://localhost:7351/
   ```

5. **Run the Flutter app**
   ```bash
   cd frontend
   flutter pub get
   flutter run -d chrome  # For web
   ```

### Building Backend Plugin (Mac Users)

```bash
./build-backend-linux.sh
docker-compose restart nakama
```

## 🌐 API/Server Configuration

### Nakama Endpoints

- **HTTP API**: `http://localhost:7351` (local) or `http://152.67.10.16:7350` (production)
- **WebSocket**: `ws://localhost:7350` (local) or `ws://152.67.10.16:7350` (production)
- **Admin Console**: `http://localhost:7351` (credentials: admin/password)

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

## 🧪 Testing Multiplayer Functionality

### Test Scenario 1: Basic Matchmaking

1. Open `http://152.67.10.16:7351` in browser
2. Click "Find Match" → Select "Classic Mode"
3. Open a second browser window (incognito)
4. Click "Find Match" → Select "Classic Mode"
5. Both players should be matched and see the game board
6. Take turns making moves and verify win detection

### Test Scenario 2: Timer Mode

1. Start matchmaking with "Timer Mode" in both windows
2. Observe the 30-second countdown timer
3. Let timer expire without moving
4. Verify opponent wins automatically

### Test Scenario 3: Disconnection Handling

1. Start a game between two players
2. Close one browser window
3. Verify remaining player receives a win after ~10 seconds

### Test Scenario 4: Leaderboard

1. Complete several games
2. Navigate to Leaderboard screen
3. Verify player statistics display correctly

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
│   └── types.go               # Data structures
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
└── DEPLOYMENT.md              # Production deployment guide
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file:

```env
DB_PASSWORD=your_secure_password
SESSION_KEY=your_random_session_key
NAKAMA_SERVER_URL=http://localhost:7351
```

### Nakama Configuration

- **Database**: PostgreSQL connection string
- **Session expiry**: 7200 seconds (2 hours)
- **Logger level**: INFO
- **Runtime path**: `/nakama/data/modules` (Go plugins)

## 🐛 Troubleshooting

### Backend won't start

```bash
docker-compose logs nakama
# Common issues: PostgreSQL not ready, port in use, plugin loading error
```

### Frontend can't connect

```bash
curl http://localhost:7351/
# Verify NAKAMA_SERVER_URL in Flutter app
```

### Plugin loading errors (Mac)

```bash
./build-backend-linux.sh
docker-compose restart nakama
```

## 📝 Development

### Running Tests

**Backend:**
```bash
cd backend
go test ./... -v
```

**Frontend:**
```bash
cd frontend
flutter test
```

### Code Style

- **Go**: Follow standard Go conventions, use `gofmt`
- **Dart**: Follow Flutter style guide, use `dart format`

---

**Made by Agampreet Singh**

**For Lila Games Backend Role**

**LinkedIn**: https://linkedin.com/in/agam1092005

**Email**: asingh11_be23@thapar.edu
