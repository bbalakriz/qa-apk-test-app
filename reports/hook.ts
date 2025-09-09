import { AfterStep } from '@cucumber/cucumber';

AfterStep(async function ({ pickleStep }) {
  // Take screenshot of the current Android emulator screen
  const screenshot = await driver.takeScreenshot();

  // Attach to Allure report
  await this.attach(screenshot, 'image/png');
});
