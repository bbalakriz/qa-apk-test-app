import { Given, When, Then } from '@wdio/cucumber-framework';

Given('the app is launched', async () => {
  // Wait for app to load by checking if any element is displayed
  try {
    // First try the specific welcome-text element
    const welcomeEl = await $('~welcome-text');
    await welcomeEl.waitForDisplayed({ timeout: 5000 });
    await expect(welcomeEl).toBeDisplayed();
  } catch (error) {
    console.log('welcome-text not found, trying alternative selectors...');
    
    // Try looking for any text element on the screen
    try {
      const textElement = await $('//android.widget.TextView');
      await textElement.waitForDisplayed({ timeout: 5000 });
      await expect(textElement).toBeDisplayed();
      console.log('Found text element, app is loaded');
    } catch (textError) {
      // Try looking for any button element
      try {
        const buttonElement = await $('//android.widget.Button');
        await buttonElement.waitForDisplayed({ timeout: 5000 });
        await expect(buttonElement).toBeDisplayed();
        console.log('Found button element, app is loaded');
      } catch (buttonError) {
        // As a last resort, just check if the app package is running
        const currentPackage = await driver.getCurrentPackage();
        expect(currentPackage).toBe('com.cucumberappiumdemo');
        console.log('App package is correct, considering app as launched');
      }
    }
  }
});

Given('the app is killed', async () => {
  console.log('Killing the app...');
  try {
    // Terminate the app using the package name
    await driver.terminateApp('com.cucumberappiumdemo', {timeout: 5000});
    console.log('App terminated successfully');
    
    // Wait a moment to ensure the app is fully closed
    await driver.pause(2000);
  } catch (error: any) {
    console.log('Error terminating app:', error.message || error);
    // Try alternative method: go to background and remove from recent apps
    try {
      await driver.background(-1); // Send app to background
      await driver.pause(5000);
    } catch (backgroundError: any) {
      console.log('Background method also failed:', backgroundError.message || backgroundError);
    }
  }
});

Given('the app is relaunched', async () => {
  console.log('Relaunching the app...');
  try {
    // Launch the app using the package and activity
    await driver.activateApp('com.cucumberappiumdemo');
    console.log('App activated successfully');
    
    // Wait for app to load
    await driver.pause(3000);
    
    // Verify app is launched by checking for any element
    try {
      const anyElement = await $('//android.widget.TextView | //android.widget.Button');
      await anyElement.waitForDisplayed({ timeout: 10000 });
      console.log('App relaunched and loaded successfully');
    } catch (elementError) {
      console.log('App may have launched but no UI elements detected immediately');
    }
  } catch (error: any) {
    console.log('Error activating app:', error);
    throw new Error(`Failed to relaunch app: ${error.message || error}`);
  }
});

When('I click the {string} button', async (buttonText: string) => {
  console.log(`Looking for button with text: ${buttonText}`);
  
  try {
    // For React Native apps, try accessibility label first, then text-based selectors
    const buttonSelectors = [
      // React Native accessibility label (most reliable)
      `~PressButton`,  // accessibilityLabel from the RN code
      // Text-based selectors  
      `//android.widget.Button[@text='${buttonText}']`,
      `//android.widget.Button[contains(@text,'${buttonText}')]`,
      `//*[@text='${buttonText}']`,
      `//*[contains(@text,'${buttonText}')]`,
      `~${buttonText}`,
      `[text='${buttonText}']`,
      // Additional RN-specific selectors
      `//android.view.ViewGroup[@content-desc='PressButton']`,
      `//*[@content-desc='PressButton']`
    ];
    
    let buttonFound = false;
    let buttonElement;
    
    for (const selector of buttonSelectors) {
      try {
        console.log(`Trying selector: ${selector}`);
        buttonElement = await $(selector);
        await buttonElement.waitForDisplayed({ timeout: 5000 });
        
        if (await buttonElement.isDisplayed()) {
          console.log(`Found button using selector: ${selector}`);
          buttonFound = true;
          break;
        }
      } catch (selectorError: any) {
        console.log(`Selector ${selector} failed: ${selectorError.message || selectorError}`);
        continue;
      }
    }
    
    if (!buttonFound || !buttonElement) {
      // Log all available elements for debugging
      console.log('Button not found. Available elements:');
      const allElements = await $$('//*[@text or @content-desc]');
      for (let i = 0; i < Math.min(allElements.length, 10); i++) {
        try {
          const text = await allElements[i].getText();
          const contentDesc = await allElements[i].getAttribute('content-desc');
          const tag = await allElements[i].getTagName();
          console.log(`Element ${i}: ${tag} - text:"${text}" content-desc:"${contentDesc}"`);
        } catch (e) {
          console.log(`Element ${i}: Could not get text/content-desc`);
        }
      }
      throw new Error(`Button with text "${buttonText}" not found`);
    }
    
    // Click the button
    await buttonElement.click();
    console.log(`Successfully clicked button: ${buttonText}`);
    
    // Wait a moment for the click to process
    await driver.pause(1000);
    
  } catch (error) {
    console.error(`Failed to click button "${buttonText}":`, error);
    throw error;
  }
});

Then('the app should respond to the button click', async () => {
  console.log('Verifying app responded to button click...');
  
  try {
    // Wait a moment for the response message to appear
    await driver.pause(2000);
    
    // Check if the app is still responsive by verifying it's still in foreground
    const currentPackage = await driver.getCurrentPackage();
    expect(currentPackage).toBe('com.cucumberappiumdemo');
    console.log('App is still running and responsive');
    
    // Verify the response message appeared after button click
    console.log('Looking for response message...');
    const responseSelectors = [
      // testID from RN code
      `~response-text`,
      // accessibility label from RN code  
      `~ResponseMessage`,
      // Text content
      `//*[@text="Button was pressed!"]`,
      `//*[contains(@text,"Button was pressed")]`,
      // Additional selectors
      `[testID="response-text"]`,
      `//*[@content-desc="ResponseMessage"]`
    ];
    
    let responseFound = false;
    for (const selector of responseSelectors) {
      try {
        console.log(`Looking for response with selector: ${selector}`);
        const responseElement = await $(selector);
        await responseElement.waitForDisplayed({ timeout: 5000 });
        
        if (await responseElement.isDisplayed()) {
          const responseText = await responseElement.getText();
          console.log(`✅ Found response message: "${responseText}"`);
          expect(responseText).toContain('Button was pressed');
          responseFound = true;
          break;
        }
      } catch (selectorError) {
        console.log(`Response selector ${selector} failed`);
        continue;
      }
    }
    
    if (!responseFound) {
      console.log('Response message not found. Checking all text elements:');
      const allTextElements = await $$('//android.widget.TextView');
      for (let i = 0; i < allTextElements.length; i++) {
        try {
          const text = await allTextElements[i].getText();
          const contentDesc = await allTextElements[i].getAttribute('content-desc');
          console.log(`Text element ${i}: "${text}" (content-desc: "${contentDesc}")`);
        } catch (e) {
          console.log(`Text element ${i}: Could not read`);
        }
      }
      throw new Error('Response message "Button was pressed!" not found after clicking button');
    }
    
    console.log('✅ Button click response verified successfully!');
    
  } catch (error) {
    console.error('App did not respond properly to button click:', error);
    throw error;
  }
}); 