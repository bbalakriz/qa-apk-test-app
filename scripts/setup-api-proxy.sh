#!/bin/bash

# QA APK API Proxy Setup
# Routes hardcoded APK API calls (192.168.0.88:8080) to 172.20.15.76:8080
# Works with Android emulator and Podman backend

set -e

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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS. For Linux, use the alternative solution in setup-api-proxy-linux.sh"
    exit 1
fi

ACTION=${1:-start}

case $ACTION in
    start)
        print_status "Setting up API proxy for hardcoded APK IP (192.168.0.88:8080 -> 172.20.15.76:8080)..."
        
        # Step 1: Create virtual network interface
        print_status "Creating virtual network interface for 192.168.0.88..."
        sudo ifconfig lo0 alias 192.168.0.88 up || {
            print_warning "Virtual interface might already exist, continuing..."
        }
        
        # Verify the interface
        if ifconfig lo0 | grep -q "192.168.0.88"; then
            print_status "✅ Virtual interface created successfully"
        else
            print_error "❌ Failed to create virtual interface"
            exit 1
        fi
        
        # Step 2: Start simple port forwarding using socat (much simpler than nginx)
        print_status "Starting port forwarding (192.168.0.88:8080 -> 172.20.15.76:8080)..."
        
        # Check if socat is available
        if ! command -v socat &> /dev/null; then
            print_warning "socat not found, installing via Homebrew..."
            if command -v brew &> /dev/null; then
                brew install socat || {
                    print_error "Failed to install socat. Please install manually: brew install socat"
                    exit 1
                }
            else
                print_error "Homebrew not found. Please install socat manually: brew install socat"
                print_error "Or install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
        fi
        
        # Kill any existing socat process on this port
        pkill -f "socat.*192.168.0.88:8080" 2>/dev/null || true
        
        # Start socat in background
        print_status "Starting socat port forwarder..."
        nohup socat TCP-LISTEN:8080,bind=192.168.0.88,reuseaddr,fork TCP:172.20.15.76:8080 > /tmp/qa-proxy.log 2>&1 &
        SOCAT_PID=$!
        
        # Save PID for cleanup
        echo $SOCAT_PID > /tmp/qa-proxy.pid
        
        # Give it a moment to start
        sleep 2
        
        # Check if socat is running
        if kill -0 $SOCAT_PID 2>/dev/null; then
            print_status "✅ Port forwarder started (PID: $SOCAT_PID)"
        else
            print_error "Failed to start port forwarder"
            exit 1
        fi
        
        # Wait for proxy to start
        sleep 3
        
        # Test the setup
        print_status "Testing proxy setup..."
        if curl -s --connect-timeout 5 http://192.168.0.88:8080/health 2>/dev/null || \
           curl -s --connect-timeout 5 http://192.168.0.88:8080/ 2>/dev/null; then
            print_status "✅ Proxy is responding on 192.168.0.88:8080"
        else
            print_warning "⚠️  Proxy started but backend might not be ready yet"
            print_warning "Make sure your backend API is running on 172.20.15.76:8080"
        fi
        
        print_status "🎉 API proxy setup complete!"
        echo ""
        echo "✅ Your APK calls to http://192.168.0.88:8080/* will now route to 172.20.15.76:8080"
        echo "✅ Start your backend API on 172.20.15.76:8080"
        echo "✅ The proxy will automatically forward all requests"
        echo ""
        echo "To stop the proxy: $0 stop"
        echo "To check status: $0 status"
        ;;
        
    stop)
        print_status "Stopping API proxy..."
        
        # Stop socat process
        if [ -f /tmp/qa-proxy.pid ]; then
            SOCAT_PID=$(cat /tmp/qa-proxy.pid)
            if kill -0 $SOCAT_PID 2>/dev/null; then
                print_status "Stopping socat process (PID: $SOCAT_PID)..."
                kill $SOCAT_PID 2>/dev/null || true
                sleep 1
                # Force kill if still running
                kill -9 $SOCAT_PID 2>/dev/null || true
            fi
            rm -f /tmp/qa-proxy.pid
        fi
        
        # Kill any remaining socat processes
        pkill -f "socat.*192.168.0.88:8080" 2>/dev/null || true
        
        # Remove virtual interface (optional - it doesn't hurt to leave it)
        print_status "Removing virtual network interface..."
        sudo ifconfig lo0 -alias 192.168.0.88 2>/dev/null || print_warning "Interface might not exist"
        
        # Clean up log files
        rm -f /tmp/qa-proxy.log 2>/dev/null || true
        
        print_status "✅ API proxy stopped"
        ;;
        
    status)
        print_status "Checking API proxy status..."
        
        # Check virtual interface
        if ifconfig lo0 | grep -q "192.168.0.88"; then
            print_status "✅ Virtual interface (192.168.0.88) is active"
        else
            print_warning "❌ Virtual interface not found"
        fi
        
        # Check socat process
        if [ -f /tmp/qa-proxy.pid ]; then
            SOCAT_PID=$(cat /tmp/qa-proxy.pid)
            if kill -0 $SOCAT_PID 2>/dev/null; then
                print_status "✅ Socat port forwarder is running (PID: $SOCAT_PID)"
            else
                print_warning "❌ Socat process not running (stale PID file)"
                rm -f /tmp/qa-proxy.pid
            fi
        else
            if pgrep -f "socat.*192.168.0.88:8080" >/dev/null; then
                print_warning "⚠️  Socat process running but no PID file found"
            else
                print_warning "❌ Socat port forwarder not running"
            fi
        fi
        
        # Test connectivity
        if curl -s --connect-timeout 3 http://192.168.0.88:8080/ >/dev/null 2>&1; then
            print_status "✅ Proxy is responding on 192.168.0.88:8080"
        else
            print_warning "❌ Proxy not responding (backend might be down)"
        fi
        ;;
        
    *)
        echo "Usage: $0 {start|stop|status}"
        echo ""
        echo "Commands:"
        echo "  start  - Set up the API proxy (192.168.0.88:8080 -> 172.20.15.76:8080)"
        echo "  stop   - Stop the proxy and clean up"
        echo "  status - Check if proxy is working"
        exit 1
        ;;
esac