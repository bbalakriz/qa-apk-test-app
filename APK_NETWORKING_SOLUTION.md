# 🔀 APK Networking Solution

**Problem**: Your APK is hardcoded to call `http://192.168.0.88:8080/rest/RetrieveJourneyAPI/...` but your backend API runs on `localhost:8080` in Podman.

**Solution**: Create a network proxy that routes the hardcoded IP to your local backend without modifying the APK.

## 🚀 Quick Start

### For macOS (Recommended):
```bash
# 1. Start the API proxy
npm run proxy:start

# 2. Start your backend API on localhost:8080 (in Podman)
./docker/start-hybrid.sh

# 3. Run your tests
npm test

# 4. When done, clean up
npm run proxy:stop
```

### For Linux:
```bash
# 1. Start the API proxy (Linux version)
npm run proxy:linux

# 2. Start your backend API on localhost:8080
./docker/start-hybrid.sh

# 3. Run your tests
npm test

# 4. Clean up
./scripts/setup-api-proxy-linux.sh stop
```

## 🔧 How It Works

### macOS Solution:
1. **Virtual Network Interface**: Creates `192.168.0.88` as an alias on the loopback interface
2. **Nginx Proxy**: Runs an nginx container that listens on `192.168.0.88:8080` and forwards to `localhost:8080`
3. **Android Emulator**: When the APK calls `http://192.168.0.88:8080/...`, it reaches the host machine
4. **Request Flow**: APK → 192.168.0.88:8080 → nginx proxy → localhost:8080 (your backend)

### Linux Solution:
1. **Virtual IP**: Adds `192.168.0.88` to the loopback interface using `ip addr`
2. **iptables Forwarding**: Uses iptables NAT rules to forward traffic from `192.168.0.88:8080` to `localhost:8080`
3. **Direct Routing**: More efficient than proxy, native OS-level forwarding

## 📱 Emulator Network Context

From Android emulator perspective:
- `localhost` = emulator's internal localhost (not your host machine)
- `10.0.2.2` = host machine's localhost
- `192.168.0.88` = external IP (resolved by host machine networking)

Our solution makes `192.168.0.88` resolvable on the host machine and forwards to the correct backend.

## 🎛️ Available Commands

```bash
# Proxy Management
npm run proxy:start      # Start proxy (macOS)
npm run proxy:stop       # Stop proxy (macOS)  
npm run proxy:status     # Check proxy status
npm run proxy:linux      # Start proxy (Linux)

# Manual Control
./scripts/setup-api-proxy.sh start|stop|status
./scripts/setup-api-proxy-linux.sh start|stop|status
```

## ✅ Verification

Test that the proxy is working:

```bash
# Check proxy status
npm run proxy:status

# Test the proxied endpoint (replace with your actual endpoint)
curl http://192.168.0.88:8080/rest/RetrieveJourneyAPI/1.0.0/health

# Should return the same as:
curl http://localhost:8080/rest/RetrieveJourneyAPI/1.0.0/health
```

## 🔍 Troubleshooting

### "Connection Refused" Errors:
1. **Check proxy status**: `npm run proxy:status`
2. **Verify backend is running**: `curl http://localhost:8080/health`
3. **Restart proxy**: `npm run proxy:stop && npm run proxy:start`

### "Command not found: podman-compose":
```bash
# Install podman-compose if needed
pip3 install podman-compose
```

### macOS "Permission denied" for network interface:
- The script needs `sudo` to create network interfaces
- You'll be prompted for your password

### Linux iptables permission issues:
- The script needs `sudo` for iptables rules
- Ensure your user can run sudo commands

## 🧹 Cleanup

The proxy automatically cleans up when stopped, but if needed:

### macOS:
```bash
# Stop nginx container
podman stop qa-api-proxy
podman rm qa-api-proxy

# Remove virtual interface
sudo ifconfig lo0 -alias 192.168.0.88
```

### Linux:
```bash
# Remove iptables rule
sudo iptables -t nat -D OUTPUT -p tcp --dport 8080 -d 192.168.0.88 -j REDIRECT --to-port 8080

# Remove virtual IP
sudo ip addr del 192.168.0.88/32 dev lo
```

## 🚀 Alternative Solutions (If Above Doesn't Work)

### Option 1: Modify Emulator Hosts File
If you have a rooted emulator or writable system image:
```bash
# On emulator
adb shell
su  # if rooted
echo "10.0.2.2 192.168.0.88" >> /etc/hosts
```

### Option 2: ADB Port Forwarding
```bash
# Forward specific port (less flexible)
adb reverse tcp:8080 tcp:8080
```

### Option 3: Run Backend on Actual IP
Configure your backend to actually bind to `192.168.0.88:8080` instead of `localhost:8080`.

## 📋 Integration with Existing Workflow

The proxy integrates seamlessly with your existing Podman setup:

1. **Start proxy** → Creates the network route
2. **Start Podman services** → Backend API runs on localhost:8080  
3. **Run tests** → APK calls route through proxy to backend
4. **Stop proxy** → Cleans up network configuration

This solution requires **zero changes** to your APK, backend code, or test framework!

---

**🎯 Result**: Your hardcoded APK calls to `http://192.168.0.88:8080/rest/RetrieveJourneyAPI/...` now seamlessly reach your Podman backend on `localhost:8080`.