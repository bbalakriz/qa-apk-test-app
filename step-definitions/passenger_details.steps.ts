import { When } from '@wdio/cucumber-framework';

console.log('✅ checkboxSteps.ts loaded (with check-in step)');

/* -------------------------
   Tunables (adjust for speed/safety)
   ------------------------- */
const ORIGINAL_IMPLICIT_MS = 5000;
const FAST_IMPLICIT_MS = 300;
const MAX_SWIPES = 4;
const SWIPE_DURATION = 350;
const SWIPE_PAUSE = 150;
const SHORT_PAUSE_AFTER_TAP = 200;

async function setImplicit(ms: number) {
  await driver.setTimeout({ implicit: ms });
}

async function fastFindFirstAccessibilityId(id: string) {
  await setImplicit(FAST_IMPLICIT_MS);
  try {
    const raw = await driver.findElements('accessibility id', id.replace(/^~?/, ''));
    if (raw && raw.length > 0) {
      return $(`~${id.replace(/^~?/, '')}`);
    }
    return null;
  } catch {
    return null;
  } finally {
    await setImplicit(ORIGINAL_IMPLICIT_MS);
  }
}

async function fastFindByUiTextContains(text: string) {
  await setImplicit(FAST_IMPLICIT_MS);
  try {
    const raw = await driver.findElements('-android uiautomator', `new UiSelector().textContains("${text}")`);
    if (raw && raw.length > 0) {
      return $(`android=new UiSelector().textContains("${text}")`);
    }
    return null;
  } catch {
    return null;
  } finally {
    await setImplicit(ORIGINAL_IMPLICIT_MS);
  }
}

async function swipeUpOnce() {
  const { width, height } = await driver.getWindowSize();
  await driver.performActions([{
    type: 'pointer',
    id: 'finger',
    parameters: { pointerType: 'touch' },
    actions: [
      { type: 'pointerMove', duration: 0, x: Math.floor(width / 2), y: Math.floor(height * 0.80) },
      { type: 'pointerDown', button: 0 },
      { type: 'pause', duration: 80 },
      { type: 'pointerMove', duration: SWIPE_DURATION, x: Math.floor(width / 2), y: Math.floor(height * 0.20) },
      { type: 'pointerUp', button: 0 }
    ]
  }]);
  await driver.pause(SWIPE_PAUSE);
}

async function scrollToElementBySelectorOrText(selectorLike: string | undefined, textFallback?: string, maxSwipes = MAX_SWIPES) : Promise<WebdriverIO.Element> {
  for (let i = 0; i < maxSwipes; i++) {
    if (selectorLike) {
      const aid = selectorLike.startsWith('~') ? selectorLike.slice(1) : selectorLike;
      const el = await fastFindFirstAccessibilityId(aid);
      if (el) {
        console.log(`scrollToElement: found by selector "${selectorLike}" (attempt ${i+1})`);
        return el;
      }
    }
    if (textFallback) {
      const el = await fastFindByUiTextContains(textFallback);
      if (el) {
        console.log(`scrollToElement: found by text "${textFallback}" (attempt ${i+1})`);
        return el;
      }
    }

    await swipeUpOnce();
  }

  // last attempt using normal waits (throws if not found)
  if (selectorLike) {
    const aid = selectorLike.startsWith('~') ? selectorLike.slice(1) : selectorLike;
    const final = await $(`~${aid}`);
    await final.waitForDisplayed({ timeout: 4000 });
    return final;
  }
  if (textFallback) {
    const final = await $(`android=new UiSelector().textContains("${textFallback}")`);
    await final.waitForDisplayed({ timeout: 4000 });
    return final;
  }
  throw new Error('scrollToElementBySelectorOrText: nothing to search for');
}

async function getBoundingRect(el: WebdriverIO.Element) {
  // use getLocation + getSize to avoid TS issues with getRect
  const loc = await el.getLocation();
  const size = await el.getSize();
  return { x: Math.floor(loc.x), y: Math.floor(loc.y), width: Math.floor(size.width), height: Math.floor(size.height) };
}

async function tapAt(x: number, y: number) {
  await driver.performActions([{
    type: 'pointer',
    id: 'tap',
    parameters: { pointerType: 'touch' },
    actions: [
      { type: 'pointerMove', duration: 0, x: Math.floor(x), y: Math.floor(y) },
      { type: 'pointerDown', button: 0 },
      { type: 'pause', duration: 60 },
      { type: 'pointerUp', button: 0 }
    ]
  }]);
  await driver.pause(SHORT_PAUSE_AFTER_TAP);
}

async function tapCheckboxNearLabel(labelEl: WebdriverIO.Element) {
  const rect = await getBoundingRect(labelEl);
  const labelCenterY = rect.y + Math.floor(rect.height / 2);

  // tap left-of-label (checkbox is usually left)
  const offsetX = Math.max(12, Math.floor(rect.width * 0.06));
  const tapX = Math.max(4, rect.x + offsetX);
  const tapY = labelCenterY;
  console.log(`tapping left of label at (${tapX}, ${tapY})`);
  await tapAt(tapX, tapY);
  await driver.pause(120);

  // try to find native checkboxes and pick the nearest vertically
  const boxes = await $$('//android.widget.CheckBox');
  if (boxes.length > 0) {
    let best: { el: WebdriverIO.Element; dy: number } | null = null;
    for (const b of boxes) {
      try {
        const br = await getBoundingRect(b);
        const centerY = br.y + Math.floor(br.height / 2);
        const dy = Math.abs(centerY - labelCenterY);
        if (!best || dy < best.dy) best = { el: b, dy };
      } catch {
        // ignore
      }
    }
    if (best) {
      const cb = best.el;
      const checked = await cb.getAttribute('checked').catch(() => null);
      console.log(`nearest checkbox vertical delta ${best.dy}, checked=${checked}`);
      if (checked === 'true') {
        console.log('checkbox already checked');
        return;
      }
      const cr = await getBoundingRect(cb);
      const cx = cr.x + Math.floor(cr.width / 2);
      const cy = cr.y + Math.floor(cr.height / 2);
      console.log(`tapping checkbox center at (${cx}, ${cy})`);
      await tapAt(cx, cy);
      await driver.pause(150);
      const checkedAfter = await cb.getAttribute('checked').catch(() => null);
      if (checkedAfter === 'true') {
        console.log('checkbox toggled to checked');
        return;
      }
      throw new Error(`Checkbox found but didn't become checked (checkedAfter=${checkedAfter})`);
    }
  }

  // last resort: tap label center
  const lx = rect.x + Math.floor(rect.width / 2);
  const ly = rect.y + Math.floor(rect.height / 2);
  console.log(`last-resort tapping label center at (${lx}, ${ly})`);
  await tapAt(lx, ly);
  await driver.pause(120);

  // confirm
  const boxes2 = await $$('//android.widget.CheckBox');
  for (const b of boxes2) {
    try {
      const br = await getBoundingRect(b);
      const centerY = br.y + Math.floor(br.height / 2);
      if (Math.abs(centerY - labelCenterY) <= rect.height * 2) {
        const checked = await b.getAttribute('checked').catch(() => null);
        if (checked === 'true') {
          console.log('checkbox became checked after label tap');
          return;
        }
      }
    } catch { /* ignore */ }
  }
  throw new Error('tapCheckboxNearLabel: unable to confirm checkbox checked state after attempts');
}

/* -------------------------
   Steps
   ------------------------- */

When('I check the BluChip checkbox', async () => {
  const selector = '~bluchip-checkbox-box';
  const found = await scrollToElementBySelectorOrText(selector, 'BluChip', MAX_SWIPES);
  await tapCheckboxNearLabel(found);
  console.log('✅ BluChip step complete');
});

When('I check the dangerous goods declaration checkbox', async () => {
  const selector = '~declaration-checkbox-box';
  const found = await scrollToElementBySelectorOrText(selector, 'I have read and understood', MAX_SWIPES);

  // If found target itself is a checkbox, toggle it; else tap near label
  const classAttr = (await found.getAttribute('className').catch(() => null)) || '';
  if (classAttr.toString().toLowerCase().includes('check')) {
    const checked = await found.getAttribute('checked').catch(() => null);
    if (checked !== 'true') {
      await found.click();
      await driver.pause(120);
      const after = await found.getAttribute('checked').catch(() => null);
      if (after === 'true') return;
    } else {
      return;
    }
  }
  await tapCheckboxNearLabel(found);
  console.log('✅ Declaration step complete');
});

When('I tap the Check-in button', async () => {
    let checkinButton;

    // Try accessibility ID first
    try {
        checkinButton = await $('~check-in-btn');
        if (!await checkinButton.isDisplayed()) throw new Error();
    } catch {
        // Fallback: match visible text
        checkinButton = await $('android=new UiSelector().textContains("Check-in")');
    }

    // If not visible, scroll down in small increments until found
    let isVisible = await checkinButton.isDisplayed().catch(() => false);
    let attempts = 0;
    while (!isVisible && attempts < 5) {
        const { height } = await driver.getWindowRect();
        await driver.touchPerform([
            { action: 'press', options: { x: 200, y: height * 0.8 } },
            { action: 'wait', options: { ms: 300 } },
            { action: 'moveTo', options: { x: 200, y: height * 0.3 } },
            { action: 'release' }
        ]);
        isVisible = await checkinButton.isDisplayed().catch(() => false);
        attempts++;
    }

    // Wait until button is clickable
    await browser.waitUntil(
        async () => {
            const enabled = await checkinButton.getAttribute('enabled').catch(() => null);
            return enabled === 'true' || await checkinButton.isEnabled();
        },
        { timeout: 8000, timeoutMsg: 'Check-in button not clickable' }
    );

    await checkinButton.click();
});
