#!/bin/bash

# QA APK Test Automation - Environment Setup Script
# This script helps set up the testing environment for any QA engineer

set -e

echo "🚀 Setting up QA APK Test Automation Environment..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Prerequisites
echo ""
print_status "Checking prerequisites..."

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    print_success "Node.js found: $NODE_VERSION"
else
    print_error "Node.js not found. Please install Node.js 16+ from https://nodejs.org/"
    exit 1
fi

# Check npm
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    print_success "npm found: $NPM_VERSION"
else
    print_error "npm not found. Please install npm"
    exit 1
fi

# Check Java
if command_exists java; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    print_success "Java found: $JAVA_VERSION"
else
    print_error "Java not found. Please install JDK 8+"
    exit 1
fi

# Check Android SDK
if [ -n "$ANDROID_HOME" ]; then
    print_success "ANDROID_HOME found: $ANDROID_HOME"
else
    print_warning "ANDROID_HOME not set. Please set it to your Android SDK path"
    print_warning "Example: export ANDROID_HOME=/Users/\$USER/Library/Android/sdk"
fi

# Check ADB
if command_exists adb; then
    ADB_VERSION=$(adb version | head -n 1)
    print_success "ADB found: $ADB_VERSION"
else
    print_error "ADB not found. Please install Android SDK Platform Tools"
    exit 1
fi

# Install npm dependencies
echo ""
print_status "Installing npm dependencies..."
npm install

# Install Appium UiAutomator2 driver
echo ""
print_status "Installing Appium UiAutomator2 driver..."
npx appium driver install uiautomator2 || print_warning "UiAutomator2 driver might already be installed"

# Check for emulator
echo ""
print_status "Checking for Android emulator..."
if adb devices | grep -q "emulator"; then
    print_success "Android emulator is running"
else
    print_warning "No Android emulator detected. Please start an emulator before running tests"
    print_warning "You can start an emulator from Android Studio or use: emulator -avd <avd_name>"
fi

# Create necessary directories
echo ""
print_status "Creating necessary directories..."
mkdir -p screenshots
mkdir -p test-results
mkdir -p reports

print_success "Screenshots directory created"
print_success "Test results directory created"
print_success "Reports directory created"

# Make scripts executable
echo ""
print_status "Making scripts executable..."
chmod +x scripts/*.sh
print_success "Scripts are now executable"

echo ""
echo "🎉 Setup Complete!"
echo "=================="
print_success "Environment setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Place your APK file as 'app.apk' in the project root"
echo "2. Update the app package name in wdio.conf.js if needed"
echo "3. Run: npm run test:setup to verify everything works"
echo "4. Run: npm test to execute tests"
echo ""
echo "For more details, see README.md"