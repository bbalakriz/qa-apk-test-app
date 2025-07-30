#!/bin/bash

# QA APK Test Automation - Version Alignment Verification
# This script checks if local and Docker versions are aligned

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_status "Checking version alignment between local and container environments..."
echo

# Check Node.js versions
print_status "Node.js Version Check:"
LOCAL_NODE=$(node --version 2>/dev/null || echo "Not installed")
EXPECTED_NODE="v18.20.8"
NVMRC_NODE=$(cat .nvmrc 2>/dev/null || echo "No .nvmrc file")

echo "  Local Node.js:    $LOCAL_NODE"
echo "  Expected:         $EXPECTED_NODE"
echo "  .nvmrc:          v$NVMRC_NODE"

if [[ "$LOCAL_NODE" == "$EXPECTED_NODE" ]]; then
    print_success "Node.js versions are aligned"
else
    print_warning "Node.js version mismatch!"
    echo "  Run: nvm use (if you have nvm installed)"
    echo "  Or install Node.js $EXPECTED_NODE"
fi
echo

# Check Java versions
print_status "Java Version Check:"
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1 2>/dev/null || echo "Not installed")
EXPECTED_JAVA="17"

echo "  Local Java:       $JAVA_VERSION"
echo "  Expected:         $EXPECTED_JAVA"

if [[ "$JAVA_VERSION" == "$EXPECTED_JAVA" ]]; then
    print_success "Java versions are aligned"
else
    print_warning "Java version mismatch!"
    echo "  Install OpenJDK 17 or set JAVA_HOME correctly"
fi
echo

# Check Android SDK
print_status "Android SDK Check:"
ADB_VERSION=$(adb --version 2>/dev/null | head -n 1 | awk '{print $5}' || echo "Not installed")
echo "  Local ADB:        $ADB_VERSION"
echo "  Container SDK:    34.0.0"

if [[ -n "$ANDROID_HOME" ]]; then
    print_success "ANDROID_HOME is set: $ANDROID_HOME"
else
    print_warning "ANDROID_HOME not set!"
fi
echo

# Check Container Engine (Podman/Docker)
print_status "Container Engine Availability:"
if command -v podman &> /dev/null; then
    PODMAN_VERSION=$(podman --version | cut -d' ' -f3)
    print_success "Podman installed: $PODMAN_VERSION"
    
    # Check if container image exists
    if podman images | grep -q "qa-automation"; then
        print_success "QA Automation container image exists"
    else
        print_warning "QA Automation container image not built yet"
        echo "  Run: npm run podman:build"
    fi
elif command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
    print_success "Docker installed: $DOCKER_VERSION"
    
    # Check if Docker image exists
    if docker images | grep -q "qa-automation"; then
        print_success "QA Automation Docker image exists"
    else
        print_warning "QA Automation Docker image not built yet"
        echo "  Run: npm run docker:build"
    fi
else
    print_error "Neither Podman nor Docker installed!"
    echo "  Install Podman: https://podman.io/getting-started/installation"
    echo "  Or install Docker: https://docs.docker.com/get-docker/"
fi
echo

print_status "Summary:"
echo "  For 100% reproducibility, use: npm run podman:hybrid (or npm run docker:hybrid)"
echo "  For local development with aligned versions, ensure all checks above pass"