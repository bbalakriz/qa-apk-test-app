# 🐳 Podman Setup Guide

This project supports **Podman** as the preferred container engine for running QA automation tests.

## 🎯 Why Podman?

- **Daemonless**: No background daemon required
- **Rootless**: Runs without root privileges  
- **Docker-compatible**: Same commands and API
- **Secure**: Better security model
- **Lightweight**: Lower resource usage

## 📦 Installation

### macOS
```bash
# Using Homebrew
brew install podman

# Start podman machine (required on macOS)
podman machine init
podman machine start
```

### Linux (Ubuntu/Debian)
```bash
# Update package list
sudo apt update

# Install podman
sudo apt install -y podman

# Install podman-compose
pip3 install podman-compose
```

### Windows
```bash
# Using Chocolatey
choco install podman-desktop

# Or download from: https://podman.io/getting-started/installation
```

## ✅ Verification

```bash
# Check Podman installation
podman --version

# Check podman-compose
podman-compose --version

# Test with hello-world
podman run hello-world
```

## 🚀 Usage with QA Automation

```bash
# Build container image
npm run podman:build

# Run hybrid mode (recommended)
npm run podman:hybrid

# Run with container emulator
npm run podman:container-emulator

# Check versions alignment
npm run verify-versions
```

## 🔄 Docker Compatibility

The project maintains full Docker compatibility:

```bash
# All these commands work identically:
npm run podman:hybrid    # Uses Podman
npm run docker:hybrid    # Uses Docker (if available)

# Auto-detection in scripts
./docker/start-hybrid.sh  # Automatically detects Podman or Docker
```

## 🆘 Troubleshooting

**Issue**: `podman: command not found`
**Solution**: Install Podman using instructions above

**Issue**: `podman-compose: command not found`  
**Solution**: `pip3 install podman-compose`

**Issue**: Permission errors on Linux
**Solution**: Podman runs rootless by default, check `/etc/subuid` and `/etc/subgid`

**Issue**: Container can't connect to host emulator
**Solution**: Use `--network host` (automatically handled in compose files)

## 🎯 Benefits for QA Teams

1. **Consistent Environment**: Same container works everywhere
2. **Security**: Rootless execution
3. **Performance**: Lower overhead than Docker
4. **Simplicity**: No daemon management
5. **Compatibility**: Drop-in Docker replacement

## 📚 Learn More

- [Podman Official Documentation](https://docs.podman.io/)
- [Podman vs Docker Comparison](https://docs.podman.io/en/latest/Introduction.html)
- [Podman Compose Documentation](https://github.com/containers/podman-compose)