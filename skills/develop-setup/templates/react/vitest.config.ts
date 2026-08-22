// vitest.config.ts — 웹(React). unit(jsdom) + browser(chromium) 두 프로젝트. develop-fe tdd-frontend.md §1·§7.
import { defineConfig } from "vitest/config";
import { playwright } from "@vitest/browser-playwright";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    projects: [
      {
        extends: true,
        test: {
          name: "unit",
          environment: "jsdom",
          include: ["src/**/*.test.{ts,tsx}"],
          exclude: ["src/**/*.browser.test.tsx"],
          setupFiles: ["./test/setup.unit.ts"], // MSW setupServer, jest-dom
        },
      },
      {
        extends: true,
        test: {
          name: "browser",
          include: ["src/**/*.browser.test.tsx"],
          setupFiles: ["./test/setup.browser.ts"], // MSW setupWorker fixture(auto: true)
          browser: {
            enabled: true,
            provider: playwright(),
            instances: [{ browser: "chromium" }], // Chromium 전용: MSW + vi.mock 수정이 Chromium만
            headless: true,
          },
          retry: process.env.CI ? 1 : 0,
        },
        optimizeDeps: { include: ["react", "react-dom", "vitest-browser-react"] }, // CI flaky 방지
      },
    ],
    coverage: { provider: "v8", include: ["src/domains/**/model/**"] },
  },
});
// CI: browser 프로젝트는 별도 job, Playwright 바이너리 캐시, 50파일 넘으면 --shard.
