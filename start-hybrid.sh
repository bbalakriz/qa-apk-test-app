#!/bin/bash

# QA APK Test Automation - Hybrid Container Start Script  
# Framework in container, connects to host emulator
# Supports Podman
# Usage: ./start-hybrid.sh [platform]
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

echo "🐳 Starting QA Automation (Hybrid Mode - $PLATFORM_TAG)..."
echo "========================================================="

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

# Check if emulator is running
print_status "Checking for Android emulator..."
if adb devices | grep -i "emulator"; then
    print_status "✅ Android emulator is running"
    adb devices
else
    print_error "❌ No Android emulator detected!"
    echo ""
    echo "Please start an Android emulator first:"
    echo "1. Open Android Studio"
    echo "2. Go to Tools > AVD Manager"
    echo "3. Start an emulator"
    echo "4. Or use command: emulator -avd <your_avd_name>"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Check if APK exists
if [ ! -f "./app.apk" ]; then
    print_warning "⚠️  No app.apk found in project root"
    echo "Please copy your APK to the project root:"
    echo "cp /path/to/your/app.apk ../app.apk"
    echo ""
    echo "Or use the deployment script:"
    echo "npm run deploy /path/to/your/app.apk"
    echo ""
    read -p "Continue anyway? (y/N): " continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build container if needed
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

# print_status "Building container using $CONTAINER_ENGINE for platform $PLATFORM..."
# $CONTAINER_ENGINE build --platform $PLATFORM -t qa-automation:$PLATFORM_TAG -f docker/Dockerfile.ubi8 . || {
#     print_error "Failed to build container with $CONTAINER_ENGINE"
#     exit 1
# }

# Start services
print_status "Starting QA automation services..."
print_status "Appium server will be available at http://localhost:4723"

PLATFORM=$PLATFORM QA_IMAGE="qa-automation:$PLATFORM_TAG" APPIUM_IMAGE="qa-automation:$PLATFORM_TAG" $COMPOSE_CMD -f docker/docker-compose.yml up -d

# Wait for services to be ready
sleep 10

# Connect to emulator from container (required for host networking)
print_status "Connecting to emulator from container..."
$CONTAINER_ENGINE exec qa-automation adb connect host.docker.internal:5555 || print_warning "Failed to connect to emulator - you may need to accept debug popup manually"
echo -e "\033[1;41m🚨🚨  ACTION REQUIRED: Please check your emulator screen and ACCEPT any USB debugging popup if prompted! 🚨🚨\033[0m"

print_status "🎉 Services started successfully!"
echo ""
echo "Services running:"
echo "- Appium server: http://localhost:4723"
echo "- QA automation container: qa-automation"
echo ""
echo "Next steps:"
echo "- Run tests: ./docker/run-tests.sh auto"
echo "- Stop services: ./docker/stop-hybrid.sh"
echo "- View logs: $COMPOSE_CMD -f docker/docker-compose.yml logs -f"