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

// Helper to expand utility bar on mobile (collapsed by default)
async function expandUtilityBar(page) {
  const toggle = page.locator('#utility-bar-toggle');
  const content = page.locator('#utility-bar-content');

  // Check if content is hidden
  const isHidden = await content.evaluate(el => el.classList.contains('hidden'));
  if (isHidden) {
    await toggle.click();
    await expect(content).not.toHaveClass(/hidden/);
  }
}

test.describe('PWA Install Button (Mobile Utility Bar)', () => {
  test.beforeEach(async ({ page }) => {
    // Utility bar is only visible on mobile/tablet
    await page.setViewportSize({ width: 375, height: 667 });
  });

  test('utility bar install button appears on beforeinstallprompt and triggers install', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });
    await expandUtilityBar(page);

    const installItem = page.locator('#install-app-item');
    const installBtn = page.locator('#install-app-btn');

    // Install button should be hidden by default
    await expect(installItem).toHaveCSS('display', 'none');

    // Fire the synthetic beforeinstallprompt event
    await triggerBeforeInstallPrompt(page, 'accepted');

    // Install button should now be visible
    await expect(installItem).not.toHaveCSS('display', 'none');
    await expect(installBtn).toBeVisible();

    // Click the button to trigger install
    await installBtn.click();

    // After install prompt flow, button should be hidden again
    await expect(installItem).toHaveCSS('display', 'none');

    // And the global deferredPrompt should be cleared
    const deferred = await page.evaluate(() => window.deferredPrompt);
    expect(deferred).toBeNull();
  });

  test('utility bar install button hides on appinstalled event', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });
    await expandUtilityBar(page);

    const installItem = page.locator('#install-app-item');

    // Fire beforeinstallprompt to show the button
    await triggerBeforeInstallPrompt(page, 'accepted');
    await expect(installItem).not.toHaveCSS('display', 'none');

    // Simulate the browser firing the appinstalled event
    await page.evaluate(() => {
      window.dispatchEvent(new Event('appinstalled'));
    });

    // Install button should be hidden
    await expect(installItem).toHaveCSS('display', 'none');

    // And the global deferredPrompt should be cleared
    const deferred = await page.evaluate(() => window.deferredPrompt);
    expect(deferred).toBeNull();
  });

  test('install button has correct accessibility attributes', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });
    await expandUtilityBar(page);

    // Fire beforeinstallprompt to show the button
    await triggerBeforeInstallPrompt(page, 'accepted');

    const installBtn = page.locator('#install-app-btn');
    await expect(installBtn).toHaveAttribute('aria-label', 'Install app');
    await expect(installBtn).toHaveAttribute('type', 'button');
  });
});

test.describe('PWA Install Button (Desktop Sidebar)', () => {
  test.beforeEach(async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
  });

  test('sidebar install button appears on beforeinstallprompt', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    const installItem = page.locator('#sidebar-install-item');
    const installBtn = page.locator('#sidebar-install');

    // Install button should be hidden by default
    await expect(installItem).toHaveCSS('display', 'none');

    // Fire the synthetic beforeinstallprompt event
    await triggerBeforeInstallPrompt(page, 'accepted');

    // Install button should now be visible in sidebar
    await expect(installItem).not.toHaveCSS('display', 'none');
    await expect(installBtn).toBeVisible();
  });

  test('sidebar install button hides on appinstalled event', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    const installItem = page.locator('#sidebar-install-item');

    // Fire beforeinstallprompt to show the button
    await triggerBeforeInstallPrompt(page, 'accepted');
    await expect(installItem).not.toHaveCSS('display', 'none');

    // Simulate the browser firing the appinstalled event
    await page.evaluate(() => {
      window.dispatchEvent(new Event('appinstalled'));
    });

    // Install button should be hidden
    await expect(installItem).toHaveCSS('display', 'none');
  });

  test('sidebar install button has correct accessibility attributes', async ({ page }) => {
    await page.goto(home, { waitUntil: 'domcontentloaded' });

    // Fire beforeinstallprompt to show the button
    await triggerBeforeInstallPrompt(page, 'accepted');

    const installBtn = page.locator('#sidebar-install');
    await expect(installBtn).toHaveAttribute('aria-label', 'Install app');
    await expect(installBtn).toHaveAttribute('type', 'button');
  });
});
