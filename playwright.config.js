// Basic Playwright config
// To run: npx playwright test
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  retries: 0,
  timeout: 120000,
  use: {
    baseURL: 'http://localhost:4321',
    headless: true,
    trace: 'on-first-retry',
    navigationTimeout: 120000,
  },
  webServer: {
    command: 'npm run build && npm run preview',
    port: 4321,
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
