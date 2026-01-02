import { test, expect } from '@playwright/test';

test('home page loads', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Check page title
  await expect(page).toHaveTitle(/Bay Navigator/);

  // Hero section should be visible
  const heroTitle = page.locator('h1');
  await expect(heroTitle).toContainText('Bay Area');
});

test('program cards are displayed', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Wait for program cards to load
  const programCards = page.locator('[data-category]');
  await expect(programCards.first()).toBeVisible({ timeout: 10000 });

  // Should have multiple programs
  const count = await programCards.count();
  expect(count).toBeGreaterThan(10);
});

test('search filters results', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Wait for programs to load
  await page.locator('[data-category]').first().waitFor({ state: 'visible', timeout: 10000 });

  const input = page.locator('#search-input');
  await input.fill('food');

  // Wait for filter to apply
  await page.waitForTimeout(300);

  // Verify that food programs are visible
  const visibleCards = page.locator('[data-category]:not([style*="display: none"])');
  const count = await visibleCards.count();
  expect(count).toBeGreaterThan(0);
});

test('category filter works', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Wait for programs to load
  await page.locator('[data-category]').first().waitFor({ state: 'visible', timeout: 10000 });

  // Click on Food category button
  const foodButton = page.locator('.category-btn', { hasText: 'Food' });
  await foodButton.click();

  // Wait for filter to apply
  await page.waitForTimeout(300);

  // All visible cards should be food category
  const visibleCards = page.locator('[data-category="food"]:not([style*="display: none"])');
  const count = await visibleCards.count();
  expect(count).toBeGreaterThan(0);
});

test('about page loads', async ({ page }) => {
  await page.goto('/about', { waitUntil: 'domcontentloaded' });

  // Check page title
  const title = page.locator('h1');
  await expect(title).toContainText('About Bay Navigator');
});

test('eligibility page loads', async ({ page }) => {
  await page.goto('/eligibility', { waitUntil: 'domcontentloaded' });

  // Check page title
  const title = page.locator('h1');
  await expect(title).toContainText('Eligibility Guides');
});

test('dark mode toggle works', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Click theme toggle
  const themeToggle = page.locator('#theme-toggle');
  await themeToggle.click();

  // Check that dark class is added to html
  const isDark = await page.evaluate(() =>
    document.documentElement.classList.contains('dark')
  );
  expect(isDark).toBe(true);
});

test('mobile menu toggle works', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Mobile menu button should be visible
  const menuBtn = page.locator('#mobile-menu-btn');
  await expect(menuBtn).toBeVisible();

  // Click to open menu
  await menuBtn.click();

  // Mobile menu should be visible
  const mobileMenu = page.locator('#mobile-menu');
  await expect(mobileMenu).toBeVisible();
});

test('no horizontal scroll on mobile', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
  const viewportWidth = await page.evaluate(() => document.documentElement.clientWidth);
  expect(bodyWidth).toBeLessThanOrEqual(viewportWidth);
});
