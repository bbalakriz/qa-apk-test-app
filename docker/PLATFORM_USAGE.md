# Multi-Platform Podman Container Support

This directory contains scripts to build and run QA automation Podman containers for different platforms.

## ⚠️ CRITICAL SETUP REQUIREMENT

**🔴 MACHINE-SPECIFIC IP CONFIGURATION REQUIRED**

Before running ANY containerized tests, you MUST configure the bridge IP for your specific machine using Podman:

1. **Find your bridge IP**: Run `podman run -it --rm --net=host localhost/qa-automation:linux-amd64 bash` then start Appium and check output
2. **Update in TWO places**:
   - `wdio.conf.js` line ~41: `hostname: '192.168.127.2'` ← Replace with YOUR IP
   - `docker/docker-compose.yml` line ~37: `APPIUM_HOST=192.168.127.2` ← Replace with YOUR IP
3. **This varies by machine** - each setup has different bridge IPs!

**Without this step, tests will fail with "connection refused" errors.**

## Platform Support

- **Linux/WSL**: `linux/amd64` architecture for Window   s machines using WSL
- **Mac Intel**: `linux/amd64` architecture for Intel-based Macs  
- **Mac ARM**: `linux/arm64` architecture for Apple Silicon Macs (M1/M2/M3)

## Scripts Overview

### 1. `start-hybrid.sh` - Build and Start Services
Builds containers locally and starts services (no tests).

```bash
# Auto-detect platform
./docker/start-hybrid.sh

# Specific platforms
./docker/start-hybrid.sh linux      # For Linux/WSL
./docker/start-hybrid.sh mac-intel  # For Intel Macs
./docker/start-hybrid.sh mac-arm    # For Apple Silicon Macs
```

### 2. `run-tests.sh` - Run Tests Against Running Services
Executes tests against already running services.

```bash
# Auto-detect platform  
./docker/run-tests.sh

# Specific platforms
./docker/run-tests.sh linux      # Run tests on Linux/WSL
./docker/run-tests.sh mac-intel  # Run tests on Intel Macs  
./docker/run-tests.sh mac-arm    # Run tests on Apple Silicon Macs
```

### 3. `stop-hybrid.sh` - Stop Services
Stops all running QA automation services.

```bash
# Auto-detect platform
./docker/stop-hybrid.sh

# Specific platforms  
./docker/stop-hybrid.sh linux      # Stop Linux/WSL services
./docker/stop-hybrid.sh mac-intel  # Stop Intel Mac services
./docker/stop-hybrid.sh mac-arm    # Stop Apple Silicon services
```

### 4. `run-hybrid.sh` - Run Tests with Registry Images
Uses pre-built images from registry, automatically pulls if needed.

```bash
# Auto-detect platform and use registry images
./docker/run-hybrid.sh

# Specific platforms
./docker/run-hybrid.sh linux      # Use registry images on Linux/WSL
./docker/run-hybrid.sh mac-intel  # Use registry images on Intel Macs
./docker/run-hybrid.sh mac-arm    # Use registry images on Apple Silicon Macs
```

### 5. `build-all-platforms.sh` - Build for All Platforms
Builds images for all supported platforms.

```bash
./docker/build-all-platforms.sh
```

## Image Naming Convention

- **QA Automation**: `quay.io/balki404/qa-automation:PLATFORM_TAG`
- **Appium Runner**: `quay.io/balki404/qa-automation:PLATFORM_TAG`

Where `PLATFORM_TAG` is:
- `linux-amd64` for Linux/WSL and Intel Macs
- `linux-arm64` for Apple Silicon Macs

## Environment Variables

The docker-compose.yml file supports these environment variables:

- `PLATFORM`: Container platform (e.g., `linux/amd64`, `linux/arm64`)
- `IMAGE_TAG`: Platform-specific tag (e.g., `linux-amd64`, `linux-arm64`)
- `QA_IMAGE`: Full QA automation image name
- `APPIUM_IMAGE`: Full Appium runner image name

## Architecture Detection

The scripts automatically detect your system architecture:

- **macOS**: Checks `uname -m` for `arm64` vs `x86_64`
- **Linux/Other**: Defaults to `linux/amd64`

## Typical Workflow

### Development/Testing
```bash
# 1. Start services (build + start containers)
./docker/start-hybrid.sh auto

# 2. Run tests multiple times during development
./docker/run-tests.sh auto
./docker/run-tests.sh auto  # Run again after code changes

# 3. Stop services when done
./docker/stop-hybrid.sh auto
```

### Quick Testing (Registry Images)
```bash
# Use registry images, pulls automatically if needed
./docker/run-hybrid.sh auto  # Uses quay.io/balki404/qa-automation images
```

## Prerequisites

- Android emulator running on host
- APK file in project root (`app.apk`)
- Podman installed ([Installation Guide](https://podman.io/getting-started/installation))

## Networking Configuration

### Host Networking Configuration
Podman configuration:
1. `network_mode: "host"` is defined in `docker-compose.yml` for both services
2. WebDriver configured to connect to Appium at the bridge IP (not localhost or service name)
3. Scripts automatically execute `adb connect host.docker.internal:5555` to connect to the host emulator
4. You'll be prompted to accept any USB debugging authorization popups on the emulator screen

## Troubleshooting

### Rosetta Error on Mac
If you see rosetta errors, make sure you're using the correct platform:
- Apple Silicon: Use `mac-arm` 
- Intel Mac: Use `mac-intel`

### Image Not Found
If you get "image not found" errors:
1. Run `build-all-platforms.sh` to build locally
2. Or ensure registry images exist for your platform
3. Check platform detection with `uname -m`

### Permission Issues
The containers now use `/tmp` directories for writable content, avoiding permission issues with `/app` directory.

### Emulator Connection Issues
If tests can't connect to the emulator:
1. Check if the emulator is running: `adb devices`
2. Ensure USB debugging is enabled on the emulator  
3. Look for USB debugging authorization popup on emulator screen and accept it
4. The scripts automatically run `adb connect host.docker.internal:5555` from the container
5. If connection still fails, manually run from inside container:
   ```bash
   podman exec qa-automation adb connect host.docker.internal:5555
   ```

### Appium Connection Issues
If tests show "getaddrinfo ENOTFOUND appium-server" or "connect ECONNREFUSED":
1. This indicates a bridge IP configuration issue
2. The `wdio.conf.js` must be configured with your machine's Podman bridge IP
3. Verify `APPIUM_HOST=YOUR_BRIDGE_IP` is set in the container environment
4. Use the container method to find your IP: See [IP_CONFIGURATION.md](../IP_CONFIGURATION.md)
5. Check if Appium server is running: `curl http://YOUR_BRIDGE_IP:4723/status`