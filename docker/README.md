# 🐳 QA APK Test Automation - Containerization Guide

## 📊 **Containerization Assessment**

### ✅ **What CAN be Containerized:**
- ✅ Node.js & npm packages
- ✅ Java JDK
- ✅ Android SDK & command-line tools
- ✅ Appium server & drivers
- ✅ Test framework code
- ✅ WebdriverIO & Cucumber

### ⚠️ **What's CHALLENGING:**
- ❌ Android emulator (needs hardware acceleration)
- ❌ GUI applications
- ❌ Hardware device connections

## 🎯 **Two Containerization Strategies**

### 🔧 **Strategy 1: Hybrid (Recommended)**
**Framework in container + Host emulator**

```bash
# Start emulator on host first
emulator -avd MyAVD

# Run containerized tests  
npm run docker:hybrid
```

**Pros:** Simple, reliable, uses existing emulator, QA can watch tests visually  
**Cons:** Still need emulator setup on host

### 🏢 **Strategy 2: Container Emulator**
**Complete containerized solution with VNC viewing**

```bash
# Everything in containers with VNC viewer
npm run docker:container-emulator

# View emulator at http://localhost:8080 (VNC)
```

**Pros:** Completely self-contained, no local emulator needed  
**Cons:** Performance limitations, no direct visual feedback

---

## 🚀 **Quick Start Options**

### Option A: Hybrid Setup (Recommended)

```bash
# 1. Ensure emulator is running
adb devices

# 2. Run hybrid tests (QA can watch visually)
npm run docker:hybrid

# 3. Tests run on your visible emulator
```

### Option B: Container Emulator Setup

```bash
# 1. Everything in containers
npm run docker:container-emulator

# 2. View emulator via VNC at http://localhost:8080
```

### Option C: Development Mode

```bash
# Interactive container for development
docker run -it --rm \
  -v $(pwd):/app \
  -v $(pwd)/screenshots:/app/screenshots \
  --network="host" \
  qa-automation:latest bash

# Inside container
npm test
```

---

## 📋 **Setup Instructions**

### Prerequisites for QA Teams:
```bash
# Only Docker needed!
docker --version
docker-compose --version

# For Hybrid: Android emulator running
adb devices
```

### 1. Build the Container:
```bash
cd docker/
docker build -t qa-automation .
```

### 2. Choose Your Approach:

#### Hybrid (Host Emulator):
```bash
# Start your emulator first
emulator -avd your_avd_name &

# Run tests
npm run docker:hybrid
```

#### Container Emulator:
```bash
# Everything in containers
npm run docker:container-emulator

# View at http://localhost:8080
```

### 3. View Results:
```bash
# Test results
ls test-results/

# Screenshots
ls screenshots/

# Logs
ls logs/
```

---

## 🔧 **Configuration Files**

| File | Purpose |
|------|---------|
| `Dockerfile` | Standard container with Android SDK |
| `docker-compose.yml` | Hybrid setup (host emulator) |
| `docker-compose.container-emulator.yml` | Full container setup with VNC |
| `start-hybrid.sh` | Automated hybrid setup script |

---

## 🎯 **Benefits for QA Teams**

### Before Containerization:
❌ Install Node.js, Java, Android Studio  
❌ Configure Android SDK & emulators  
❌ Set environment variables  
❌ Install npm packages  
❌ Debug platform-specific issues  

### After Containerization:
✅ `docker-compose up` - Done!  
✅ Consistent environment across teams  
✅ No local dependency conflicts  
✅ Easy CI/CD integration  

---

## 🌍 **CI/CD Integration**

> **Note:** CI/CD environments don't have host emulators, so we use the **Container Emulator** setup for automated pipelines.

### GitHub Actions:
```yaml
name: QA Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Run QA Tests (Container Emulator)
      run: |
        npm run docker:container-emulator -- --abort-on-container-exit
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: test-results/
```

### Jenkins Pipeline:
```groovy
pipeline {
    agent any
    stages {
        stage('QA Tests') {
            steps {
                sh 'npm run docker:container-emulator -- --abort-on-container-exit'
            }
        }
    }
    post {
        always {
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'test-results',
                reportFiles: '*.html',
                reportName: 'QA Test Report'
            ])
            archiveArtifacts artifacts: 'screenshots/**', allowEmptyArchive: true
        }
    }
}
```

---

## 🔍 **Troubleshooting**

### Container can't reach emulator:
```bash
# Use host networking
docker run --network="host" qa-automation

# Or check emulator IP
adb shell ip route
```

### Performance issues:
```bash
# Allocate more resources
docker run -m 4g --cpus=2 qa-automation
```

---

## 📊 **Cost-Benefit Analysis**

| Approach | Setup Time | Monthly Cost | Maintenance | Scalability |
|----------|------------|--------------|-------------|-------------|
| **Manual Setup** | 2-4 hours | $0 | High | Low |
| **Hybrid Container** | 30 minutes | $0 | Medium | Medium |
| **Container Emulator** | 15 minutes | $0 | Low | Medium |

## 🎉 **Recommendation**

**For most QA teams: Start with Hybrid approach**
- Quick setup (30 minutes vs 4 hours)
- Zero ongoing costs
- Visual feedback on real emulator
- Easy to understand and maintain

**For teams without local emulators: Use Container Emulator**
- No local emulator setup needed
- Completely self-contained
- VNC viewing available
- Good for CI/CD pipelines

---

## 📞 **Support**

For containerization questions:
1. Check logs: `docker-compose logs`
2. Debug mode: `docker run -it qa-automation bash`
3. VNC viewer: `http://localhost:8080` (for container emulator)
4. Troubleshooting: Check main README.md for common issues