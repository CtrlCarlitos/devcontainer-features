# Playwright

Installs [Playwright](https://playwright.dev) globally plus a browser —
giving AI coding agents real browser automation (page navigation, scraping,
clicking, screenshotting, end-to-end testing) without any local setup.

## Usage

Add to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/devcontainers/features/node:1": {},
        "ghcr.io/CtrlCarlitos/devcontainer-features/playwright:1": {}
    }
}
```

## Options

| Option    | Default    | Description                                 |
|-----------|------------|---------------------------------------------|
| `browser` | `chromium` | Browser engine: `chromium`, `firefox`, `webkit` |

## What it does

- Requires Node.js (install the node feature first — `installsAfter` is set)
- Runs `npm install -g playwright` for the CLI/library
- Runs `npx --yes playwright install --with-deps <browser>` — downloads the
  browser **and** its required system libraries (apt-based bases only)
- Links `playwright` into `/usr/local/bin` for minimal devcontainer shells
- Idempotent — skips the browser download if the engine is already present

## ⚠️ Size warning

Browsers install to `~/.cache/ms-playwright` and are large:

- chromium: ~170 MB
- firefox: ~250 MB
- webkit: ~400 MB

Plus ~10 MB for the npm package and system deps. Account for this in image
size and disk budgets.

## Typical use

```js
const { chromium } = require('playwright');
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('https://example.com');
await page.screenshot({ path: 'example.png' });
await browser.close();
```
