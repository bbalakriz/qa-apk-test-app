#!/bin/bash

# QA APK Test Automation - Run Tests Against Running Services
# Assumes services are already started with start-hybrid.sh
# Supports Podman
# Usage: ./run-tests.sh [platform]
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

echo "🧪 Running QA Tests ($PLATFORM_TAG)..."
echo "===================================="

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
print_status "Checking if QA automation services are running..."
if ! $CONTAINER_ENGINE ps | grep -q "qa-automation\|appium-server"; then
    print_error "❌ QA automation services are not running!"
    echo ""
    echo "Please start the services first:"
    echo "  ./docker/start-hybrid.sh $PLATFORM_ARG"
    echo ""
    exit 1
fi

print_status "✅ Services are running"

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
    exit 1
fi

# Check if APK exists
if [ ! -f "./app.apk" ]; then
    print_warning "⚠️  No app.apk found in project root"
    echo "Please copy your APK to the project root:"
    echo "cp /path/to/your/app.apk ./app.apk"
    echo ""
    read -p "Continue anyway? (y/N): " continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run tests
print_status "Running tests..."
print_status "Test results will be saved to ./test-results/"
print_status "Screenshots will be saved to ./screenshots/"

# Connect to emulator from container (required for host networking)
print_status "Connecting to emulator from container..."
$CONTAINER_ENGINE exec qa-automation adb connect host.docker.internal:5555 || print_warning "Failed to connect to emulator - you may need to accept debug popup manually"
echo -e "\033[1;41m🚨🚨  ACTION REQUIRED: Please check your emulator screen and ACCEPT any USB debugging popup if prompted! 🚨🚨\033[0m"

# Execute tests in the qa-automation container
PLATFORM=$PLATFORM QA_IMAGE="qa-automation:$PLATFORM_TAG" APPIUM_IMAGE="qa-automation:$PLATFORM_TAG" $COMPOSE_CMD -f docker/docker-compose.yml exec qa-automation npm test

# Show results
echo ""
print_status "🎉 Test execution completed!"
echo ""
echo "Results:"
echo "- Test reports: ./test-results/"
echo "- Screenshots: ./screenshots/"
echo "- Logs: ./logs/"