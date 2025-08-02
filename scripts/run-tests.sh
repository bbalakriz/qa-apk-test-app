#!/bin/bash

# QA APK Test Automation - Test Execution Script
# This script manages the complete test execution process

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

# Function to check if Appium is running
check_appium() {
    if curl -s http://127.0.0.1:4723/status >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to start Appium
start_appium() {
    print_status "Starting Appium server..."
    
    # Kill any existing Appium processes
    pkill -f "appium" || true
    sleep 2
    
    # Start Appium in background
    npx appium --port 4723 > logs/appium.log 2>&1 &
    APPIUM_PID=$!
    
    # Wait for Appium to start
    print_status "Waiting for Appium to start..."
    for i in {1..30}; do
        if check_appium; then
            print_success "Appium server started successfully (PID: $APPIUM_PID)"
            echo $APPIUM_PID > .appium.pid
            return 0
        fi
        sleep 1
        echo -n "."
    done
    
    print_error "Failed to start Appium server"
    return 1
}

# Function to stop Appium
stop_appium() {
    if [ -f ".appium.pid" ]; then
        PID=$(cat .appium.pid)
        print_status "Stopping Appium server (PID: $PID)..."
        kill $PID 2>/dev/null || true
        rm -f .appium.pid
        print_success "Appium server stopped"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking test prerequisites..."
    
    # Check if APK exists
    if [ ! -f "app.apk" ]; then
        print_error "app.apk not found in project root"
        print_error "Please copy your APK to the project root and name it 'app.apk'"
        print_error "Or use: ./scripts/manage-apk.sh deploy /path/to/your/app.apk"
        exit 1
    fi
    
    # Check emulator
    if ! adb devices | grep -i "emulator"; then
        print_error "No Android emulator detected"
        print_error "Please start an Android emulator before running tests"
        exit 1
    fi
    
    # Check if app is installed
    PACKAGE_NAME=$(grep "appPackage" wdio.conf.js | cut -d"'" -f4)
    if ! adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
        print_warning "App not installed on emulator"
        print_status "Installing app..."
        adb install app.apk
    fi
    
    print_success "Prerequisites check passed"
}

# Function to run tests
run_tests() {
    local test_type="$1"
    
    print_status "Running tests..."
    
    case "$test_type" in
        "smoke")
            print_status "Running smoke tests..."
            npx wdio run wdio.conf.js --cucumberOpts.tagExpression='@smoke'
            ;;
        "regression")
            print_status "Running regression tests..."
            npx wdio run wdio.conf.js
            ;;
        "feature")
            if [ -z "$2" ]; then
                print_error "Feature file required for feature tests"
                exit 1
            fi
            print_status "Running feature tests: $2"
            npx wdio run wdio.conf.js --spec="features/$2"
            ;;
        *)
            print_status "Running all tests..."
            npx wdio run wdio.conf.js
            ;;
    esac
}

# Function to generate report
generate_report() {
    print_status "Generating test report..."
    
    # Create a simple HTML report
    cat > test-results/report.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>QA Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .success { color: green; }
        .failure { color: red; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>QA Test Automation Results</h1>
        <p class="timestamp">Generated: $(date)</p>
    </div>
    
    <h2>Test Summary</h2>
    <p>Check the console output and logs directory for detailed results.</p>
    
    <h2>Screenshots</h2>
    <p>Screenshots are saved in the screenshots/ directory</p>
    
    <h2>Logs</h2>
    <p>Appium logs are saved in logs/appium.log</p>
</body>
</html>
EOF
    
    print_success "Test report generated: test-results/report.html"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    stop_appium
    print_success "Cleanup completed"
}

# Trap cleanup on script exit
trap cleanup EXIT

# Function to display usage
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  test              Run all tests"
    echo "  smoke            Run smoke tests only"
    echo "  regression       Run regression tests"
    echo "  feature <file>   Run specific feature file"
    echo "  setup            Setup and verify environment"
    echo ""
    echo "Examples:"
    echo "  $0 test"
    echo "  $0 smoke"
    echo "  $0 feature launch-app.feature"
    echo "  $0 setup"
}

# Create logs directory
mkdir -p logs

# Main script logic
case "$1" in
    "test"|"")
        check_prerequisites
        start_appium
        run_tests "all"
        generate_report
        ;;
        
    "smoke")
        check_prerequisites
        start_appium
        run_tests "smoke"
        generate_report
        ;;
        
    "regression")
        check_prerequisites
        start_appium
        run_tests "regression"
        generate_report
        ;;
        
    "feature")
        if [ -z "$2" ]; then
            print_error "Feature file required"
            usage
            exit 1
        fi
        check_prerequisites
        start_appium
        run_tests "feature" "$2"
        generate_report
        ;;
        
    "setup")
        print_status "Running environment setup verification..."
        check_prerequisites
        if start_appium; then
            print_success "Appium started successfully"
            stop_appium
            print_success "Setup verification completed!"
        else
            print_error "Setup verification failed"
            exit 1
        fi
        ;;
        
    *)
        print_error "Unknown command: $1"
        usage
        exit 1
        ;;
esac

print_success "Test execution completed!"