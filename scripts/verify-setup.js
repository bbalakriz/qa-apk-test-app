#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔍 Verifying QA Test Automation Setup...\n');

const checks = [
  {
    name: 'Node.js',
    command: 'node --version',
    required: true
  },
  {
    name: 'npm',
    command: 'npm --version',
    required: true
  },
  {
    name: 'Java',
    command: 'java -version',
    required: true
  },
  {
    name: 'ADB (Android Debug Bridge)',
    command: 'adb version',
    required: true
  },
  {
    name: 'Appium',
    command: 'appium --version',
    required: false
  }
];

const files = [
  {
    name: 'APK file',
    path: './app.apk',
    required: true
  },
  {
    name: 'Package.json',
    path: './package.json',
    required: true
  },
  {
    name: 'WebdriverIO config',
    path: './wdio.conf.js',
    required: true
  }
];

let allPassed = true;

// Check commands
console.log('📋 Checking required software...');
checks.forEach(check => {
  try {
    execSync(check.command, { stdio: 'pipe' });
    console.log(`✅ ${check.name}: Found`);
  } catch (error) {
    if (check.required) {
      console.log(`❌ ${check.name}: Not found or not working`);
      allPassed = false;
    } else {
      console.log(`⚠️  ${check.name}: Not found (will be installed during setup)`);
    }
  }
});

console.log('\n📁 Checking required files...');
files.forEach(file => {
  if (fs.existsSync(file.path)) {
    console.log(`✅ ${file.name}: Found`);
  } else {
    if (file.required) {
      console.log(`❌ ${file.name}: Missing`);
      if (file.name === 'APK file') {
        console.log('   💡 Place your APK file in the project root and rename it to "app.apk"');
      }
      allPassed = false;
    }
  }
});

console.log('\n🔧 Checking environment variables...');
const androidHome = process.env.ANDROID_HOME || process.env.ANDROID_SDK_ROOT;
if (androidHome) {
  console.log(`✅ ANDROID_HOME: ${androidHome}`);
} else {
  console.log('⚠️  ANDROID_HOME: Not set');
  console.log('   💡 Set ANDROID_HOME environment variable to your Android SDK path');
}

console.log('\n📱 Checking connected devices...');
try {
  const devices = execSync('adb devices', { encoding: 'utf8' });
  const deviceLines = devices.split('\n').filter(line => line.includes('\tdevice'));
  if (deviceLines.length > 0) {
    console.log(`✅ Connected devices: ${deviceLines.length}`);
    deviceLines.forEach(line => {
      const deviceId = line.split('\t')[0];
      console.log(`   📱 ${deviceId}`);
    });
  } else {
    console.log('⚠️  No devices connected');
    console.log('   💡 Start an Android emulator or connect a physical device');
  }
} catch (error) {
  console.log('❌ Could not check devices (ADB not working)');
  allPassed = false;
}

console.log('\n' + '='.repeat(50));
if (allPassed) {
  console.log('🎉 Setup verification completed successfully!');
  console.log('You can now run: npm run setup && npm test');
} else {
  console.log('❌ Setup verification failed. Please fix the issues above.');
  console.log('\nNext steps:');
  console.log('1. Install missing software');
  console.log('2. Set environment variables');
  console.log('3. Place your APK file as app.apk');
  console.log('4. Run this script again');
}
console.log('='.repeat(50)); 