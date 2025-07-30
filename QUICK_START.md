# 🚀 Quick Start Guide

**Get up and running in 3 minutes!**

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

**Issue**: Tests fail to connect
**Solution**: `npm run appium` in a separate terminal

**Issue**: App shows red screen
**Solution**: Use release APK, not debug APK

**Issue**: Element not found
**Solution**: Check element IDs in your app

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