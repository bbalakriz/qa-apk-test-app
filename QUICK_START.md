# 🚀 Quick Start Guide

**Get up and running in 4 minutes!** *(Now includes Appium setup)*

## 📋 Prerequisites (1 minute)

Before starting, ensure you have:

✅ **Node.js 16+** installed  
✅ **Java JDK 8+** installed  
✅ **Android Studio** with SDK installed  
✅ **Android emulator** running  

Quick check:
```bash
node --version    # Should show v16+
java -version     # Should show 1.8+
adb devices       # Should show an emulator
```

## 🚀 Setup (1 minute)

```bash
# 1. Clone and enter directory
git clone <this-repo>
cd qa-apk-test-automation

# 2. One-command setup (installs everything)
npm run setup
```

## 📱 Deploy APK (30 seconds)

```bash
# Option A: Auto-deploy (recommended)
npm run deploy /path/to/your/app.apk

# Option B: Manual copy
cp /path/to/your/app.apk ./app.apk
```

## 🚀 Start Appium Server (30 seconds)

**Important**: Appium must be running before tests can execute.

```bash
# Option A: Start Appium manually (recommended for development)
npm run appium

# Keep this terminal open - Appium runs in foreground
# Open a new terminal for running tests
```

```bash
# Option B: Auto-start with tests (simpler for CI/CD)
npm test
# This automatically starts/stops Appium for you
```

## 🧪 Run Tests (30 seconds)

```bash
# Quick smoke test
npm run test:smoke

# All tests
npm test
```

## ✅ Success!

If everything works, you should see:
- ✅ App launches on emulator
- ✅ Tests pass
- ✅ Screenshots saved
- ✅ Report generated

## 🆘 Troubleshooting

**Issue**: Tests fail to connect to Appium
**Solution**: 
- Check if Appium is running: `curl http://127.0.0.1:4723/status`
- If not running: `npm run appium` in a separate terminal
- Wait 10-15 seconds for Appium to fully start

**Issue**: App shows red screen
**Solution**: Use release APK, not debug APK

**Issue**: Element not found
**Solution**: Check element IDs in your app with `adb shell uiautomator dump`

**Issue**: Emulator not detected
**Solution**: Ensure emulator is running: `adb devices` should show your device

## 📝 Next Steps

1. **Write your first test** - Edit `features/launch-app.feature`
2. **Add more scenarios** - Use the step library in README.md
3. **Run tests regularly** - Integrate into your CI/CD

## 🎯 Example Test

```gherkin
Feature: My App Test

  @smoke
  Scenario: App launches successfully
    Given the app is launched
    When I tap on element with id "welcomeButton"
    Then I should see element containing text "Welcome"
```

---

**🎉 You're ready to automate! Check README.md for advanced features.**