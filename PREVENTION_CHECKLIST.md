# 🛡️ ESM Error Prevention Checklist

**Follow this checklist on every new machine to prevent the ESM compatibility errors.**

## ✅ Pre-Setup Checklist

### 1. Version Check (CRITICAL)
```bash
# Before doing anything else, verify exact versions:
node --version    # Must be: v18.20.8
java -version     # Must be: 17.0.16  
adb --version     # Must be: 1.0.41
```

### 2. If Versions Don't Match
```bash
# Install exact Node.js version
nvm install 18.20.8
nvm use 18.20.8

# Install exact Java version (OpenJDK 17.0.16)
# Download from: https://www.oracle.com/java/technologies/downloads/

# Update Android SDK platform-tools for ADB 1.0.41
# Via Android Studio SDK Manager
```

### 3. Verify Alignment
```bash
# After installation, run:
npm run check-versions

# Should show all green checkmarks
```

## ✅ Setup Checklist

### 1. Clean Installation
```bash
# Clone repository
git clone <repo-url>
cd qa-apk-test-automation

# Check versions FIRST
npm run check-versions

# Install dependencies
npm run setup
```

### 2. Test Installation
```bash
# Verify everything works
npm run appium &
sleep 5
npm test
```

## ✅ Alternative: Container Setup

**Skip all version issues entirely:**

```bash
# Clone repository
git clone <repo-url>
cd qa-apk-test-automation

# Use containers (guaranteed to work)
npm run podman:hybrid
```

## 🚨 Red Flags (Stop and Fix)

❌ **Wrong Node.js version** → ESM module errors
❌ **Wrong Java version** → Build/compilation issues  
❌ **Wrong ADB version** → Device connection problems
❌ **Caret (^) in package.json** → Version drift
❌ **Missing package-lock.json** → Inconsistent installs

## ✅ Success Indicators

✅ `npm run check-versions` shows all green
✅ `npm install` completes without errors
✅ `npm test` runs without module errors
✅ Appium connects to emulator successfully

## 🎯 For QA Teams

### Team Lead Setup:
1. Ensure all team members follow this checklist
2. Provide exact version installation instructions
3. Set up container environment as backup
4. Document any team-specific requirements

### Team Member Setup:
1. **Always** run version check first
2. **Never** skip version verification
3. **Use containers** if local setup issues
4. **Ask for help** if versions don't match

## 📋 Quick Commands Reference

```bash
# Version checking
npm run check-versions      # Check all versions
node --version              # Check Node.js  
java -version               # Check Java
adb --version               # Check ADB

# Setup commands
npm run setup               # Full environment setup
npm install                 # Install dependencies
npm run appium             # Start Appium server

# Testing commands  
npm test                   # Run all tests
npm run test:smoke         # Run smoke tests

# Container commands (backup option)
npm run podman:hybrid      # Use Podman containers
npm run docker:hybrid      # Use Docker containers
```

---

**Remember**: 2 minutes of version checking saves hours of debugging! 🛡️