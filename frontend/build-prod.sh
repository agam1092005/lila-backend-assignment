#!/bin/bash

# Production build script for Flutter web frontend
# This script builds the Flutter web app with production configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Flutter Web Production Build ===${NC}"

# Check if NAKAMA_SERVER_URL is set
if [ -z "$NAKAMA_SERVER_URL" ]; then
    echo -e "${YELLOW}Warning: NAKAMA_SERVER_URL not set${NC}"
    echo -e "${YELLOW}Using default: https://your-domain.com:7351${NC}"
    NAKAMA_SERVER_URL="https://your-domain.com:7351"
fi

echo -e "${GREEN}Building with Nakama server URL: $NAKAMA_SERVER_URL${NC}"

# Clean previous build
echo -e "${GREEN}Cleaning previous build...${NC}"
flutter clean

# Get dependencies
echo -e "${GREEN}Getting dependencies...${NC}"
flutter pub get

# Build for web with release mode
echo -e "${GREEN}Building Flutter web app (release mode)...${NC}"
flutter build web \
    --release \
    --dart-define=NAKAMA_SERVER_URL="$NAKAMA_SERVER_URL" \
    --web-renderer canvaskit

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build completed successfully!${NC}"
    echo -e "${GREEN}Output directory: build/web${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Deploy to Firebase Hosting: firebase deploy --only hosting"
    echo "  2. Deploy to Vercel: cd build/web && vercel --prod"
    echo "  3. Deploy to custom server: Copy build/web/* to your web server"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
