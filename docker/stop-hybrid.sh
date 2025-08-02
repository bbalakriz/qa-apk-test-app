#!/bin/bash

# QA APK Test Automation - Stop Hybrid Services
# Stops services that were started with start-hybrid.sh
# Supports Podman
# Usage: ./stop-hybrid.sh [platform]
# Platforms: linux (for WSL), mac-intel, mac-arm, or auto-detect

set -e

# Parse platform argument
PLATFORM_ARG=${1:-auto}

case $PLATFORM_ARG in
    linux|wsl)
        PLATFORM="linux/amd64"
        PLATFORM_TAG="linux-amd64"
        ;;
    mac-intel)
        PLATFORM="linux/amd64"
        PLATFORM_TAG="linux-amd64"
        ;;
    mac-arm|mac-silicon)
        PLATFORM="linux/amd64"
        PLATFORM_TAG="linux-amd64"
        ;;
    auto)
        # Auto-detect platform
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if [[ $(uname -m) == "arm64" ]]; then
                PLATFORM="linux/amd64"
                PLATFORM_TAG="linux-amd64"
                echo "🔍 Auto-detected: Apple Silicon Mac (using amd64 for Android SDK compatibility)"
            else
                PLATFORM="linux/amd64" 
                PLATFORM_TAG="linux-amd64"
                echo "🔍 Auto-detected: Intel Mac"
            fi
        else
            PLATFORM="linux/amd64"
            PLATFORM_TAG="linux-amd64"
            echo "🔍 Auto-detected: Linux/WSL"
        fi
        ;;
    *)
        echo "❌ Invalid platform: $PLATFORM_ARG"
        echo "Valid options: linux, mac-intel, mac-arm, auto"
        exit 1
        ;;
esac

echo "🛑 Stopping QA Automation Services ($PLATFORM_TAG)..."
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for Podman
if command -v podman &> /dev/null; then
    CONTAINER_ENGINE="podman"
    COMPOSE_CMD="podman-compose"
else
    print_error "Podman not found!"
    echo "Please install Podman:"
    echo "  Podman: https://podman.io/getting-started/installation"
    exit 1
fi

# Check if services are running
print_status "Checking for running QA automation services..."
if ! $CONTAINER_ENGINE ps | grep -q "qa-automation\|appium-server"; then
    print_warning "⚠️  No QA automation services appear to be running"
    echo ""
    echo "To see all containers: $CONTAINER_ENGINE ps -a"
else
    print_status "✅ Found running services"
fi

# Stop services
print_status "Stopping QA automation services..."
PLATFORM=$PLATFORM QA_IMAGE="qa-automation:$PLATFORM_TAG" APPIUM_IMAGE="qa-automation:$PLATFORM_TAG" $COMPOSE_CMD -f docker/docker-compose.yml down

print_status "🎉 Services stopped successfully!"
echo ""
echo "To restart:"
echo "  ./docker/start-hybrid.sh $PLATFORM_ARG"
echo ""
echo "To view stopped containers:"
echo "  $CONTAINER_ENGINE ps -a"