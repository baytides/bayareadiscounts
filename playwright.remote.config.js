// Remote Playwright config targeting the deployed Static Web App
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  retries: 0,
  timeout: 120000,
  use: {
    baseURL: 'https://wonderful-coast-09041e01e.2.azurestaticapps.net',
    headless: true,
    trace: 'on-first-retry',
    navigationTimeout: 120000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
