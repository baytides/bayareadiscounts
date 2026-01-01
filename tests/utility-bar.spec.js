const { test, expect } = require('@playwright/test');

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

test.describe('Utility Bar (Mobile)', () => {
  test.beforeEach(async ({ page }) => {
    // Set mobile viewport - utility bar is hidden on desktop (controls in sidebar)
    await page.setViewportSize({ width: 375, height: 667 });
    // Use ?no-step=1 to skip the onboarding wizard
    await page.goto('/?no-step=1');
    // Expand utility bar (collapsed by default on mobile)
    await expandUtilityBar(page);
  });

  test('utility bar is visible on mobile', async ({ page }) => {
    // Check utility bar is visible
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).toBeVisible();

    // Utility bar content should be visible after expanding
    const content = page.locator('#utility-bar-content');
    await expect(content).toBeVisible();
  });

  test('theme selector works on mobile', async ({ page }) => {
    const themeSelect = page.locator('#theme-select');

    // Check theme select is visible
    await expect(themeSelect).toBeVisible();

    // Check options exist
    await expect(themeSelect).toHaveValue('auto');

    // Change to dark mode
    await themeSelect.selectOption('dark');
    await expect(page.locator('body')).toHaveAttribute('data-theme', 'dark');

    // Change to light mode
    await themeSelect.selectOption('light');
    await expect(page.locator('body')).toHaveAttribute('data-theme', 'light');
  });

  test('utility buttons are accessible on mobile', async ({ page }) => {
    // Check spacing toggle button
    const spacingToggle = page.locator('#spacing-toggle');
    await expect(spacingToggle).toBeVisible();
    await expect(spacingToggle).toHaveAttribute('aria-label', /toggle enhanced text spacing/i);

    // Check share button
    const shareBtn = page.locator('#share-btn');
    await expect(shareBtn).toBeVisible();
    await expect(shareBtn).toHaveAttribute('aria-label', /share/i);
  });

  test('keyboard navigation works on mobile', async ({ page }) => {
    // Focus on the theme select directly
    const themeSelect = page.locator('#theme-select');
    await themeSelect.focus();
    await expect(themeSelect).toBeFocused();

    // Tab to next control (spacing toggle)
    await page.keyboard.press('Tab');
    const spacingToggle = page.locator('#spacing-toggle');
    await expect(spacingToggle).toBeFocused();

    // Tab to next control (share button)
    await page.keyboard.press('Tab');
    const shareBtn = page.locator('#share-btn');
    await expect(shareBtn).toBeFocused();
  });

  test('preferences persist after page reload on mobile', async ({ page }) => {
    // Set dark theme
    const themeSelect = page.locator('#theme-select');
    await themeSelect.selectOption('dark');

    // Wait for localStorage to be set
    await page.waitForTimeout(100);

    // Reload page
    await page.reload();

    // Wait for page to load
    await page.waitForLoadState('domcontentloaded');

    // Check preferences were saved
    await expect(page.locator('body')).toHaveAttribute('data-theme', 'dark');
  });
});

test.describe('Utility Bar Hidden on Desktop', () => {
  test('utility bar is hidden on desktop with sidebar', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/?no-step=1');

    // Utility bar should be hidden on desktop
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).not.toBeVisible();

    // Sidebar should be visible instead
    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();
  });
});
