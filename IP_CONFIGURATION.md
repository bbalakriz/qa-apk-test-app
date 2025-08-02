# 🔴 CRITICAL: Podman Bridge IP Configuration

This file explains the machine-specific IP configuration required for Podman containerized tests.

## Why This Is Required

When using Podman containers with host networking, the test container needs to connect to the Appium server. The bridge IP varies by machine and Podman configuration.

## How to Find Your Bridge IP

### The ONLY Reliable Method: Container Test

```bash
# 1. Start container with host networking
podman run -it --rm --net=host localhost/qa-automation:linux-amd64 bash

# 2. Inside the container, start Appium and check what IPs it listens on
export APPIUM_HOME=/tmp/appium
export HOME=/tmp
npm run appium | grep http

# 3. Look for output like:
# [Appium] Appium REST http interface listener started on http://0.0.0.0:4723
# 	http://127.0.0.1:4723/ (only accessible from the same host)
# 	http://192.168.127.2:4723/  ← THIS IS YOUR BRIDGE IP!

# 4. Use the bridge IP (not 127.0.0.1) in your configuration
```

**Why this is the only reliable method:**
- Other IP detection commands often give wrong results
- This method shows exactly what IPs Appium can actually listen on
- It tests the exact same Podman network configuration your tests will use

## Common Podman Bridge IPs by Platform

| Platform | Most Common IP | Alternative IPs |
|----------|----------------|----------------|
| Linux | `10.88.0.1` | `192.168.127.2`, `172.17.0.1` |
| macOS | `192.168.127.2` | `10.88.0.1`, `172.17.0.1` |
| WSL2 | varies | `192.168.127.2`, `10.88.0.1` |

**⚠️ IMPORTANT**: Don't rely on these common IPs! Always use the Podman container method above to find YOUR specific IP.

## Required Updates

### 1. Update wdio.conf.js
```javascript
// Line ~41
hostname: process.env.APPIUM_HOST || 'YOUR_BRIDGE_IP_HERE',
```

### 2. Update docker/docker-compose.yml
```yaml
# Line ~37
- APPIUM_HOST=YOUR_BRIDGE_IP_HERE
```

## Verification

After updating the IP, verify it works:

```bash
# Start your Podman containers
./docker/start-hybrid.sh

# In another terminal, test the connection
curl http://YOUR_BRIDGE_IP_HERE:4723/status

# Should return Appium status JSON

# Or use the container test method again to double-check:
podman run -it --rm --net=host localhost/qa-automation:linux-amd64 bash
# Then run: npm run appium | grep http
```

## Troubleshooting

### Error: "connect ECONNREFUSED"
- Wrong bridge IP configured
- Use the commands above to find correct IP

### Error: "getaddrinfo ENOTFOUND" 
- Usually hostname resolution issue
- Make sure you're using IP, not hostname

### Error: "timeout"
- Appium server may not be running
- Check with: `podman ps`

---

**Remember**: This IP must be updated on EVERY machine that runs the tests!