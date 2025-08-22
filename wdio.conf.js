const path = require('path');

exports.config = {
    // Runner Configuration
    runner: 'local',
    
    // Test Files
    specs: [
        './features/**/*launch*.feature'
    ],
    
    // Patterns to exclude
    exclude: [],
    
    // Capabilities
    capabilities: [{
        // capabilities for local Appium web tests on an Android Emulator
        platformName: 'Android',
        'appium:platformVersion': '16.0', // or your emulator version
        'appium:deviceName': 'Android Emulator',
        'appium:automationName': 'UiAutomator2',
        
        // Path to your APK file - UPDATE THIS PATH
        'appium:app': path.join(process.cwd(), 'app.apk'), // Place your APK in project root
        
        // App package and activity - UPDATE THESE BASED ON YOUR APK
        'appium:appPackage': 'com.cucumberappiumdemo', // Replace with your app's package name
        // 'appium:appPackage': 'com.agenticmobilecheckinapp', // Replace with your app's package name
        'appium:appActivity': '.MainActivity', // Replace with your app's main activity
        
        // Additional capabilities - use fresh session for each scenario
        'appium:noReset': true,   // Don't reset app state between tests
        'appium:fullReset': false, // Don't reinstall app
        'appium:newCommandTimeout': 240,
        'appium:androidInstallTimeout': 90000
    }],
    
    // Test Configuration
    logLevel: 'info',
    bail: 0,
    baseUrl: 'http://host.containers.internal',
    hostname: process.env.APPIUM_HOST || '127.0.0.1', //'192.168.127.2', // CRITICAL: Update this IP for your machine! See QUICK_START.md 
    port: 4723,
    path: '/',
    maxInstances: 1, // Run tests sequentially to avoid conflicts
    waitforTimeout: 10000,
    connectionRetryTimeout: 120000,
    connectionRetryCount: 3,
    
    // Services
    services: [
        // Appium service removed - start manually: npx appium --port 4723
    ],
    
    // Framework
    framework: 'cucumber',
    
    // Reporters
    reporters: ['spec'],
    
    // Cucumber options
    cucumberOpts: {
        require: ['./step-definitions/**/*launch*.ts'],
        backtrace: false,
        requireModule: [
            'ts-node/register'
        ],
        dryRun: false,
        failFast: false,
        snippets: true,
        source: true,
        strict: false,
        tagExpression: '',
        timeout: 60000,
        ignoreUndefinedDefinitions: false
    },
    
    // Hooks
    onPrepare: function (config, capabilities) {
        console.log('Starting test execution...');
    },
    
    onComplete: function(exitCode, config, capabilities, results) {
        console.log('Test execution completed.');
    },
    
    beforeSession: function (config, capabilities, specs) {
        console.log('Creating new session...');
    },
    
    before: function (capabilities, specs) {
        // Set implicit wait
        driver.setTimeout({ 'implicit': 5000 });
    },
    
    beforeScenario: function (world, context) {
        console.log(`Starting scenario...`);
        // Small delay to ensure app is ready
        if (typeof driver !== 'undefined') {
            driver.pause(1000);
        }
    },
    
    afterSession: function (config, capabilities, specs) {
        console.log('Session ended.');
    }
}; 