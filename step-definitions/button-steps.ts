import { When, Then } from '@wdio/cucumber-framework';

When('I press the {string}', async (buttonId: string) => {
  const button = await $(`~${buttonId}`);
  await button.click();
});

Then('I should see the response message', async () => {
  const response = await $('~ResponseMessage');
  await expect(response).toBeDisplayed();
});
