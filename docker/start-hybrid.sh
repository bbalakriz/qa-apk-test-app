#!/bin/bash

# QA APK Test Automation - Hybrid Container Start Script  
# Framework in container, connects to host emulator
# Supports both Docker and Podman

set -e

echo "🐳 Starting QA Automation (Hybrid Mode)..."
echo "========================================"

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

# Build container if needed
# Auto-detect container engine
if command -v podman &> /dev/null; then
    CONTAINER_ENGINE="podman"
    COMPOSE_CMD="podman-compose"
elif command -v docker &> /dev/null; then
    CONTAINER_ENGINE="docker"
    COMPOSE_CMD="docker-compose"
else
    print_error "Neither Podman nor Docker found!"
    echo "Please install one of them:"
    echo "  Podman: https://podman.io/getting-started/installation"
    echo "  Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

print_status "Building container using $CONTAINER_ENGINE..."
$CONTAINER_ENGINE build -t qa-automation -f docker/Dockerfile . || {
    print_error "Failed to build container with $CONTAINER_ENGINE"
    exit 1
}

# Run tests
print_status "Starting containerized tests..."
print_status "Test results will be saved to ../test-results/"
print_status "Screenshots will be saved to ../screenshots/"

$COMPOSE_CMD up --abort-on-container-exit qa-automation

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
$COMPOSE_CMD down