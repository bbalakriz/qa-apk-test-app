#!/bin/bash

# QA APK Test Automation - Multi-Platform Build Script
# Builds containers for both Linux (WSL) and Mac architectures
# Supports both Docker and Podman

set -e

echo "🏗️  Building QA Automation for All Platforms..."
echo "==============================================="

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

# Auto-detect container engine
if command -v podman &> /dev/null; then
    CONTAINER_ENGINE="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_ENGINE="docker"
else
    print_error "Neither Podman nor Docker found!"
    echo "Please install one of them:"
    echo "  Podman: https://podman.io/getting-started/installation"
    echo "  Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

print_status "Using container engine: $CONTAINER_ENGINE"

# Define platforms and images
PLATFORMS=("linux/amd64" "linux/arm64")
PLATFORM_TAGS=("linux-amd64" "linux-arm64")
QA_IMAGE_BASE="quay.io/balki404/qa-automation"
APPIUM_IMAGE_BASE="quay.io/balki404/appium-runner"

# Build for each platform
for i in "${!PLATFORMS[@]}"; do
    PLATFORM="${PLATFORMS[$i]}"
    PLATFORM_TAG="${PLATFORM_TAGS[$i]}"
    
    print_status "Building for platform: $PLATFORM (tag: $PLATFORM_TAG)"
    
    # Build QA Automation image
    print_status "Building QA Automation image..."
    $CONTAINER_ENGINE build \
        --platform $PLATFORM \
        -t $QA_IMAGE_BASE:$PLATFORM_TAG \
        -f docker/Dockerfile.ubi8 . || {
        print_error "Failed to build QA Automation image for $PLATFORM"
        exit 1
    }
    
    # Build Appium Runner image (same Dockerfile for now)
    print_status "Building Appium Runner image..."
    $CONTAINER_ENGINE build \
        --platform $PLATFORM \
        -t $APPIUM_IMAGE_BASE:$PLATFORM_TAG \
        -f docker/Dockerfile.ubi8 . || {
        print_error "Failed to build Appium Runner image for $PLATFORM"
        exit 1
    }
    
    print_status "✅ Successfully built images for $PLATFORM"
    echo ""
done

print_status "🎉 All platform builds completed!"
echo ""
echo "Built images:"
for i in "${!PLATFORM_TAGS[@]}"; do
    PLATFORM_TAG="${PLATFORM_TAGS[$i]}"
    echo "  - $QA_IMAGE_BASE:$PLATFORM_TAG"
    echo "  - $APPIUM_IMAGE_BASE:$PLATFORM_TAG"
done

echo ""
print_status "To push to registry, run:"
for i in "${!PLATFORM_TAGS[@]}"; do
    PLATFORM_TAG="${PLATFORM_TAGS[$i]}"
    echo "  $CONTAINER_ENGINE push $QA_IMAGE_BASE:$PLATFORM_TAG"
    echo "  $CONTAINER_ENGINE push $APPIUM_IMAGE_BASE:$PLATFORM_TAG"
done

echo ""
print_status "Usage examples:"
echo "  Linux/WSL:     ./docker/run-hybrid.sh linux"
echo "  Mac Intel:     ./docker/run-hybrid.sh mac-intel" 
echo "  Mac ARM:       ./docker/run-hybrid.sh mac-arm"
echo "  Auto-detect:   ./docker/run-hybrid.sh auto"