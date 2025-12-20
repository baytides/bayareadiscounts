import { test, expect } from '@playwright/test';

const home = '/';

// Helper to fire a synthetic beforeinstallprompt event
async function triggerBeforeInstallPrompt(page, outcome = 'accepted') {
  await page.evaluate(async (desiredOutcome) => {
    const e = new Event('beforeinstallprompt');
    // Provide the properties our app code expects
    e.prompt = () => {};
    e.userChoice = Promise.resolve({ outcome: desiredOutcome });
    // Dispatch the event
    window.dispatchEvent(e);
  }, outcome);
}

test('footer install link enables on beforeinstallprompt and triggers install', async ({ page }) => {
  await page.goto(home, { waitUntil: 'domcontentloaded' });

  const installLink = page.locator('#footer-install-link');
  await expect(installLink).toHaveAttribute('aria-disabled', 'true');

  // Fire the synthetic beforeinstallprompt event
  await triggerBeforeInstallPrompt(page, 'accepted');

  // Link should be enabled
  await expect(installLink).not.toHaveAttribute('aria-disabled', 'true');
  await expect(installLink).toHaveAttribute('data-install-available', 'true');

  // Badge should be visible and live region should announce availability
  const badge = page.locator('#install-badge');
  await expect(badge).toBeVisible();
  const liveText = await page.locator('#install-live').innerText();
  expect(liveText).toMatch(/install is available/i);

  // Click the link to trigger install
  await installLink.click();

  // After install prompt flow, it should disable again
  await expect(installLink).toHaveAttribute('aria-disabled', 'true');
  await expect(installLink).not.toHaveAttribute('data-install-available', 'true');

  // Live region should update
  // Simulate the browser firing the `appinstalled` event
  await page.evaluate(() => {
    window.dispatchEvent(new Event('appinstalled'));
  });
  const afterLiveText = await page.locator('#install-live').innerText();
  expect(afterLiveText).toMatch(/installed/i);

  // And the global deferredPrompt should be cleared
  const deferred = await page.evaluate(() => window.deferredPrompt);
  expect(deferred).toBeNull();
});
