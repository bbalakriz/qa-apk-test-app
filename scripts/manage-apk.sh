#!/bin/bash

# QA APK Test Automation - APK Management Script
# This script helps manage APK installation and deployment

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get package name from APK
get_package_name() {
    local apk_file="$1"
    if [ -f "$apk_file" ]; then
        # Try using aapt (if available)
        if command -v aapt >/dev/null 2>&1; then
            aapt dump badging "$apk_file" | grep package | awk '{print $2}' | sed 's/name=//g' | sed 's/'\''//g'
        else
            # Fallback: Try using apkanalyzer (if available)
            if command -v apkanalyzer >/dev/null 2>&1; then
                apkanalyzer manifest application-id "$apk_file"
            else
                print_warning "Cannot extract package name automatically. aapt or apkanalyzer not found."
                echo "com.yourapp.package"
            fi
        fi
    else
        print_error "APK file not found: $apk_file"
        exit 1
    fi
}

# Function to install APK
install_apk() {
    local apk_file="$1"
    local package_name="$2"
    
    print_status "Installing APK: $apk_file"
    
    # Uninstall existing app if present
    if adb shell pm list packages | grep -q "$package_name"; then
        print_status "Uninstalling existing app: $package_name"
        adb uninstall "$package_name" || print_warning "Could not uninstall existing app"
    fi
    
    # Install new APK
    print_status "Installing new APK..."
    if adb install "$apk_file"; then
        print_success "APK installed successfully!"
    else
        print_error "Failed to install APK"
        exit 1
    fi
}

# Function to launch app
launch_app() {
    local package_name="$1"
    print_status "Launching app: $package_name"
    
    # Try common activity names
    local activities=(".MainActivity" ".activity.MainActivity" ".ui.MainActivity" ".main.MainActivity")
    
    for activity in "${activities[@]}"; do
        if adb shell am start -n "$package_name$activity" 2>/dev/null; then
            print_success "App launched successfully with activity: $activity"
            return 0
        fi
    done
    
    print_warning "Could not launch app automatically. Please launch manually or check activity name."
}

# Function to check emulator
check_emulator() {
    print_status "Checking for Android emulator..."
    
    if ! adb devices | grep -q "emulator"; then
        print_error "No Android emulator detected!"
        print_error "Please start an Android emulator before proceeding."
        echo ""
        echo "To start an emulator:"
        echo "1. Open Android Studio"
        echo "2. Go to Tools > AVD Manager"
        echo "3. Start an existing emulator, or create a new one"
        echo "4. Alternatively, use command line: emulator -avd <avd_name>"
        exit 1
    else
        print_success "Android emulator is running"
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 [COMMAND] [APK_FILE]"
    echo ""
    echo "Commands:"
    echo "  install <apk_file>    Install APK to emulator"
    echo "  deploy <apk_file>     Deploy APK (copy to project + install)"
    echo "  launch <package_name> Launch app on emulator"
    echo "  check                 Check emulator status"
    echo "  info <apk_file>       Get APK information"
    echo ""
    echo "Examples:"
    echo "  $0 install /path/to/app.apk"
    echo "  $0 deploy /path/to/app.apk"
    echo "  $0 launch com.example.app"
    echo "  $0 check"
    echo "  $0 info app.apk"
}

# Main script logic
case "$1" in
    "install")
        if [ -z "$2" ]; then
            print_error "APK file path required"
            usage
            exit 1
        fi
        
        APK_FILE="$2"
        check_emulator
        PACKAGE_NAME=$(get_package_name "$APK_FILE")
        print_status "Detected package name: $PACKAGE_NAME"
        install_apk "$APK_FILE" "$PACKAGE_NAME"
        launch_app "$PACKAGE_NAME"
        ;;
        
    "deploy")
        if [ -z "$2" ]; then
            print_error "APK file path required"
            usage
            exit 1
        fi
        
        APK_FILE="$2"
        check_emulator
        
        # Copy APK to project root
        print_status "Copying APK to project root..."
        cp "$APK_FILE" "./app.apk"
        print_success "APK copied to ./app.apk"
        
        # Get package name and install
        PACKAGE_NAME=$(get_package_name "./app.apk")
        print_status "Detected package name: $PACKAGE_NAME"
        
        # Update wdio.conf.js with package name
        if [ -f "wdio.conf.js" ]; then
            print_status "Updating wdio.conf.js with package name..."
            sed -i.bak "s/'appium:appPackage': '.*'/'appium:appPackage': '$PACKAGE_NAME'/g" wdio.conf.js
            print_success "wdio.conf.js updated with package: $PACKAGE_NAME"
        fi
        
        install_apk "./app.apk" "$PACKAGE_NAME"
        launch_app "$PACKAGE_NAME"
        
        echo ""
        print_success "APK deployed successfully!"
        echo "You can now run: npm test"
        ;;
        
    "launch")
        if [ -z "$2" ]; then
            print_error "Package name required"
            usage
            exit 1
        fi
        
        check_emulator
        launch_app "$2"
        ;;
        
    "check")
        check_emulator
        print_status "Listing connected devices:"
        adb devices
        ;;
        
    "info")
        if [ -z "$2" ]; then
            print_error "APK file path required"
            usage
            exit 1
        fi
        
        APK_FILE="$2"
        if [ ! -f "$APK_FILE" ]; then
            print_error "APK file not found: $APK_FILE"
            exit 1
        fi
        
        PACKAGE_NAME=$(get_package_name "$APK_FILE")
        print_status "APK Information:"
        echo "File: $APK_FILE"
        echo "Package: $PACKAGE_NAME"
        echo "Size: $(ls -lh "$APK_FILE" | awk '{print $5}')"
        ;;
        
    *)
        print_error "Unknown command: $1"
        usage
        exit 1
        ;;
esac