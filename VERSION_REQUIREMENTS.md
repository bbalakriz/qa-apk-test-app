# 🎯 Version Requirements

**To prevent ESM compatibility errors and ensure consistent behavior across all machines, use these EXACT versions:**

## 📋 Required Versions

### Node.js
- **Required**: `18.20.8`
- **Check**: `node --version` should show `v18.20.8`
- **Install**: Use `.nvmrc` file provided

### Java
- **Required**: `OpenJDK 17.0.16`
- **Check**: `java -version` should show `17.0.16`
- **Install**: [Download OpenJDK 17.0.16](https://www.oracle.com/java/technologies/downloads/)

### Android SDK / ADB
- **Required**: `ADB 1.0.41`
- **Check**: `adb --version` should show `1.0.41`
- **Install**: Update Android SDK platform-tools

## 🚨 Why These Exact Versions?

These versions have been tested together and are known to work without ESM compatibility issues. Using different versions may cause:

- Module loading errors
- TypeScript compilation issues  
- WebDriverIO startup failures
- Dependency resolution conflicts

## ✅ Quick Verification

```bash
# Run this command to check all versions
npm run verify-versions

# Expected output:
# [✓] Node.js versions are aligned  
# [✓] Java versions are perfectly aligned
# [✓] ADB version is perfectly aligned
```

## 🔧 Installation Guide

### macOS
```bash
# Node.js with nvm
nvm install 18.20.8
nvm use 18.20.8

# Java with Homebrew
brew install openjdk@17

# Android SDK - update platform-tools via Android Studio
```

### Linux (Ubuntu/Debian)
```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs=18.20.8*

# Java
sudo apt install openjdk-17-jdk

# Android SDK via Android Studio
```

### Windows
```bash
# Node.js - download from nodejs.org
# Java - download from Oracle
# Android SDK via Android Studio
```

## 🐳 Container Alternative

If you can't install these exact versions locally, use containers:

```bash
# Perfect version alignment guaranteed
npm run podman:hybrid
# or
npm run docker:hybrid
```

## 🎯 For New Team Members

1. **First, check current versions**:
   ```bash
   node --version
   java -version  
   adb --version
   ```

2. **If versions don't match exactly**:
   ```bash
   # Option A: Install exact versions (recommended)
   # Follow installation guide above
   
   # Option B: Use containers (quick start)
   npm run podman:hybrid
   ```

3. **Verify setup**:
   ```bash
   npm run verify-versions
   ```

4. **Run tests**:
   ```bash
   npm test
   ```

## 📊 Troubleshooting

| Issue | Solution |
|-------|----------|
| Wrong Node.js version | `nvm use 18.20.8` |
| Wrong Java version | Install OpenJDK 17.0.16 |
| Wrong ADB version | Update Android SDK platform-tools |
| ESM errors | Use exact versions or containers |
| "Command not found" | Restart terminal after installation |

---

**Remember**: Exact versions = Zero compatibility issues! 🎯