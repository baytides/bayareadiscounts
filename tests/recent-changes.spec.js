const { test, expect } = require('@playwright/test');

test.describe('Recent Changes - Desktop Sidebar and Dark Mode', () => {
  test('desktop sidebar appears on index page (1024px+ viewport)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();

    // Check logo is present in sidebar
    const logo = page.locator('.sidebar-logo');
    await expect(logo).toBeVisible();
    await expect(logo).toHaveAttribute('aria-label', /Bay Area Discounts Home/i);

    // Check navigation is present
    const nav = page.locator('#desktop-sidebar nav');
    await expect(nav).toBeVisible();
  });

  test('desktop sidebar appears on privacy page', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/privacy.html');

    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();

    // Check logo is clickable and goes to home
    const logo = page.locator('.sidebar-logo');
    await expect(logo).toBeVisible();
    await expect(logo).toHaveAttribute('href', '/');
  });

  test('desktop sidebar appears only once (no duplicates)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    const sidebars = page.locator('#desktop-sidebar');
    await expect(sidebars).toHaveCount(1);
  });

  test('dark mode toggle applies correct CSS variables (mobile)', async ({ page }) => {
    // Use mobile viewport where utility bar is visible
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    const body = page.locator('body');
    const themeSelect = page.locator('#theme-select');

    // Test dark mode
    await themeSelect.selectOption('dark');
    await expect(body).toHaveAttribute('data-theme', 'dark');

    // Check that dark mode CSS variables are applied
    const bgColor = await body.evaluate((el) => {
      return getComputedStyle(el).getPropertyValue('--bg-main').trim();
    });
    expect(bgColor).toBe('#0d1117'); // Dark mode background

    // Test light mode
    await themeSelect.selectOption('light');
    await expect(body).toHaveAttribute('data-theme', 'light');

    // Check that light mode CSS variables are applied
    const lightBgColor = await body.evaluate((el) => {
      return getComputedStyle(el).getPropertyValue('--bg-main').trim();
    });
    // Browser may return 'white' or '#ffffff' depending on how it normalizes
    expect(['white', '#ffffff']).toContain(lightBgColor); // Light mode background
  });

  test('sidebar theme toggle cycles through modes (desktop)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    const body = page.locator('body');
    const themeToggle = page.locator('#sidebar-theme-toggle');
    const themeLabel = page.locator('#theme-label');

    // Initial state should be System/Auto
    await expect(themeLabel).toHaveText('System');

    // Click to cycle to Light
    await themeToggle.click();
    await expect(themeLabel).toHaveText('Light');
    await expect(body).toHaveAttribute('data-theme', 'light');

    // Click to cycle to Dark
    await themeToggle.click();
    await expect(themeLabel).toHaveText('Dark');
    await expect(body).toHaveAttribute('data-theme', 'dark');

    // Click to cycle back to Auto/System
    await themeToggle.click();
    await expect(themeLabel).toHaveText('System');
  });

  test('dark mode toggle overrides system preference (mobile)', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    const body = page.locator('body');
    const themeSelect = page.locator('#theme-select');

    // Set to light mode explicitly
    await themeSelect.selectOption('light');

    // Emulate dark color scheme preference
    await page.emulateMedia({ colorScheme: 'dark' });

    // Body should still show light mode (manual override)
    await expect(body).toHaveAttribute('data-theme', 'light');

    const bgColor = await body.evaluate((el) => {
      return getComputedStyle(el).getPropertyValue('--bg-main').trim();
    });
    // Browser may return 'white' or '#ffffff' depending on how it normalizes
    expect(['white', '#ffffff']).toContain(bgColor); // Should stay light
  });

  test('auto mode respects system preference (mobile)', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    const body = page.locator('body');
    const themeSelect = page.locator('#theme-select');

    // Set to auto mode
    await themeSelect.selectOption('auto');

    // Emulate dark color scheme
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.waitForTimeout(100); // Wait for media query to apply

    await expect(body).toHaveAttribute('data-theme', 'dark');

    // Emulate light color scheme
    await page.emulateMedia({ colorScheme: 'light' });
    await page.waitForTimeout(100);

    await expect(body).toHaveAttribute('data-theme', 'light');
  });

  test('privacy policy text is visible in dark mode (desktop via sidebar)', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/privacy.html');

    // Use sidebar theme toggle
    const themeToggle = page.locator('#sidebar-theme-toggle');

    // Click twice to get to dark mode (auto -> light -> dark)
    await themeToggle.click();
    await themeToggle.click();

    // Check content wrapper is visible
    const contentWrapper = page.locator('.content-wrapper');
    await expect(contentWrapper).toBeVisible();

    // Check that h1 exists and is visible
    const h1 = page.locator('.content-wrapper h1').first();
    await expect(h1).toBeVisible();
  });

  test('sidebar navigation links work', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    // Directory link
    const directoryLink = page.locator('.sidebar-nav-item[data-view="directory"]');
    await expect(directoryLink).toBeVisible();

    // Saved link
    const savedLink = page.locator('.sidebar-nav-item[data-view="saved"]');
    await expect(savedLink).toBeVisible();

    // For You link
    const forYouLink = page.locator('.sidebar-nav-item[data-view="for-you"]');
    await expect(forYouLink).toBeVisible();
  });

  test('responsive design on mobile (375x667)', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    // Desktop sidebar should be hidden on mobile
    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).not.toBeInViewport();

    // Utility bar should be visible on mobile
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).toBeVisible();

    // Theme select should be visible on mobile
    const themeSelect = page.locator('#theme-select');
    await expect(themeSelect).toBeVisible();
  });

  test('responsive design on tablet (768x1024)', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');

    // Desktop sidebar should be hidden on tablet (under 1024px)
    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).not.toBeInViewport();

    // Utility bar should be visible on tablet
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).toBeVisible();
  });

  test('responsive design on desktop (1920x1080)', async ({ page }) => {
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.goto('/');

    const sidebar = page.locator('#desktop-sidebar');
    await expect(sidebar).toBeVisible();

    const logo = page.locator('.sidebar-logo');
    await expect(logo).toBeVisible();

    const nav = page.locator('#desktop-sidebar nav');
    await expect(nav).toBeVisible();

    // Utility bar should be hidden on desktop
    const utilityBar = page.locator('#utility-bar');
    await expect(utilityBar).not.toBeVisible();
  });
});
