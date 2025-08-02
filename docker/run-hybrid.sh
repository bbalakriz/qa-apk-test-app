#!/bin/bash

# QA APK Test Automation - Run Hybrid Container (Registry Images)
# Always uses fresh images from quay.io registry
# Framework in container, connects to host emulator
# Supports Podman
# Usage: ./run-hybrid.sh [platform]
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

echo "🚀 Running QA Automation (Hybrid Mode - No Build - $PLATFORM_TAG)..."
echo "===================================================================="

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
if adb devices | grep -q "emulator"; then
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

# Always use registry images - pull fresh from quay.io
print_status "Using registry images from quay.io/balki404/qa-automation:$PLATFORM_TAG"

# Check if registry image already exists locally
if $CONTAINER_ENGINE images --format "{{.Repository}}:{{.Tag}}" | grep -q "quay.io/balki404/qa-automation:$PLATFORM_TAG"; then
    print_status "✅ Registry image already available locally"
else
    print_status "Pulling fresh image from registry..."
    $CONTAINER_ENGINE pull quay.io/balki404/qa-automation:$PLATFORM_TAG || {
        print_error "Failed to pull QA automation image from registry"
        echo "Please check:"
        echo "1. Internet connection"
        echo "2. Registry availability: quay.io/balki404/qa-automation:$PLATFORM_TAG"
        echo "3. Or build locally: ./docker/start-hybrid.sh $PLATFORM_ARG"
        exit 1
    }
    print_status "✅ Registry image pulled successfully"
fi

# Tag for compose compatibility (both services use same image)
$CONTAINER_ENGINE tag quay.io/balki404/qa-automation:$PLATFORM_TAG qa-automation:$PLATFORM_TAG

# Run tests
print_status "Starting containerized tests..."
print_status "Test results will be saved to ../test-results/"
print_status "Screenshots will be saved to ../screenshots/"

# Start services first
PLATFORM=$PLATFORM QA_IMAGE="qa-automation:$PLATFORM_TAG" APPIUM_IMAGE="qa-automation:$PLATFORM_TAG" $COMPOSE_CMD -f docker/docker-compose.yml up -d

# Connect to emulator from container (required for host networking)
sleep 5
print_status "Connecting to emulator from container..."
$CONTAINER_ENGINE exec qa-automation adb connect host.docker.internal:5555 || print_warning "Failed to connect to emulator - you may need to accept debug popup manually"
print_status "Please check emulator screen and accept any USB debugging popup if prompted"

# Run tests
PLATFORM=$PLATFORM QA_IMAGE="qa-automation:$PLATFORM_TAG" APPIUM_IMAGE="qa-automation:$PLATFORM_TAG" $COMPOSE_CMD -f docker/docker-compose.yml exec qa-automation npm test

# Show results
echo ""
print_status "🎉 Test execution completed!"
echo ""
echo "Results:"
echo "- Test reports: ../test-results/"
echo "- Screenshots: ../screenshots/"
echo "- Logs: ../logs/"

# Clean up
print_status "Cleaning up containers..."
PLATFORM=$PLATFORM QA_IMAGE="qa-automation:$PLATFORM_TAG" APPIUM_IMAGE="qa-automation:$PLATFORM_TAG" $COMPOSE_CMD -f docker/docker-compose.yml down