#!/bin/bash

# QA APK Test Automation - Start with API Proxy
# Integrates API proxy setup with existing hybrid container workflow
# Handles the hardcoded IP issue (192.168.0.88:8080 -> localhost:8080)

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "🚀 QA APK Test Automation with API Proxy"
echo "=========================================="
echo "Solving hardcoded IP issue: 192.168.0.88:8080 → localhost:8080"
echo ""

# Step 1: Setup API Proxy
print_header "1/4 Setting up API proxy for hardcoded APK IP..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    ./scripts/setup-api-proxy.sh start
else
    ./scripts/setup-api-proxy-linux.sh start
fi

if [ $? -ne 0 ]; then
    print_error "❌ Failed to set up API proxy"
    exit 1
fi

echo ""

# Step 2: Start Hybrid Container Setup
print_header "2/4 Starting Podman hybrid containers..."
./docker/start-hybrid.sh ${1:-auto}

if [ $? -ne 0 ]; then
    print_error "❌ Failed to start containers"
    print_warning "Cleaning up proxy..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ./scripts/setup-api-proxy.sh stop
    else
        ./scripts/setup-api-proxy-linux.sh stop
    fi
    exit 1
fi

echo ""

# Step 3: Wait for services to be ready
print_header "3/4 Waiting for services to be ready..."
sleep 5

# Verify Appium is running
print_status "Checking Appium server..."
if curl -s --connect-timeout 10 http://localhost:4723/status >/dev/null 2>&1; then
    print_status "✅ Appium server is running on localhost:4723"
else
    print_warning "⚠️  Appium server might still be starting..."
    echo "   You can check status later with: curl http://localhost:4723/status"
fi

# Verify proxy is working
print_status "Checking API proxy..."
if curl -s --connect-timeout 5 http://192.168.0.88:8080/ >/dev/null 2>&1; then
    print_status "✅ API proxy is working (192.168.0.88:8080 → localhost:8080)"
else
    print_warning "⚠️  API proxy is configured but backend might not be ready yet"
    echo "   Make sure your backend API starts on localhost:8080"
fi

echo ""

# Step 4: Ready to test
print_header "4/4 Ready to run tests!"
echo ""
echo "🎉 Complete setup finished!"
echo ""
echo "Your APK's hardcoded calls to http://192.168.0.88:8080/* will now route to localhost:8080"
echo ""
echo "Next steps:"
echo "├── 1. Start your backend API on localhost:8080 (if not already running)"
echo "├── 2. Run tests: npm test"
echo "├── 3. Or run specific features: npm run test:smoke"
echo "└── 4. Monitor logs: podman logs -f appium-server"
echo ""
echo "Cleanup when done:"
echo "├── Stop containers: ./docker/stop-hybrid.sh"
echo "└── Stop proxy: npm run proxy:stop"
echo ""
echo "Status commands:"
echo "├── Check proxy: npm run proxy:status"
echo "├── Check Appium: curl http://localhost:4723/status"
echo "└── Check emulator: adb devices"
echo ""

# Create a cleanup script for convenience
cat > /tmp/qa-cleanup.sh << 'EOF'
#!/bin/bash
echo "🧹 Cleaning up QA environment..."
./docker/stop-hybrid.sh
if [[ "$OSTYPE" == "darwin"* ]]; then
    ./scripts/setup-api-proxy.sh stop
else
    ./scripts/setup-api-proxy-linux.sh stop
fi
echo "✅ Cleanup complete!"
EOF
chmod +x /tmp/qa-cleanup.sh

print_status "💡 Quick cleanup script created: /tmp/qa-cleanup.sh"
echo ""
print_status "🚀 You're ready to test your APK with seamless API routing!"