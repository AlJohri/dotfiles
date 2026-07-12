---
name: amazon-reviews
description: 'Read Amazon product reviews reliably through the user''s logged-in Chrome session via the claude-in-chrome MCP. Use whenever the user asks to check, read, summarize, or analyze Amazon reviews for a product/ASIN. IMPORTANT: since Amazon''s May 2026 change, anonymous scrapers and WebFetch see only ~8-13 "featured" reviews (or nothing) — the full review list requires a logged-in browser session, so ALWAYS use this Chrome flow instead of WebFetch/curl/third-party scraper APIs. Also covers the gotchas: get_page_text does NOT capture the review list; expand pagination via "Show N more reviews" before extracting.'
user_invocable: false
---

# amazon-reviews — read Amazon reviews via Chrome

Read the full review list for a product through the user's real Chrome
session (claude-in-chrome MCP + `javascript_tool`). Anonymous access
(WebFetch, curl, scraper libs) gets at most the featured sample since
Amazon's May 2026 change — don't bother with it.

## Flow

1. Load Chrome MCP tools if deferred (one ToolSearch call):
   `tabs_context_mcp, navigate, javascript_tool` (+ `find, computer` for
   fallback). Get tab context; if "Browser extension is not connected",
   retry once, and if Chrome isn't running, start it
   (`setsid google-chrome-stable &`).

2. Navigate the MCP tab to the reviews page:
   `https://www.amazon.com/product-reviews/<ASIN>/?sortBy=recent`
   - `sortBy=recent` for chronological (default is "top reviews").
   - Star filter: append `&filterByStar=one_star` (`critical`, `positive`,
     `five_star`, … also valid) — useful to read the failure tail directly.
   - The ratings histogram (overall stars, % per star) is in the page header.
     NOTE: overall rating includes star-only ratings; written reviews often
     skew more negative.

3. Expand all reviews, then extract as JSON — one `javascript_tool` call:

   ```js
   const sleep = ms => new Promise(r => setTimeout(r, ms));
   for (let i = 0; i < 15; i++) {           // "Show 10 more reviews" loop
     const btn = [...document.querySelectorAll('a, button')]
       .find(e => /show \d+ more reviews/i.test(e.innerText));
     if (!btn) break;
     btn.click(); await sleep(2500);
   }
   const reviews = [...document.querySelectorAll('[data-hook="review"]')].map(r => ({
     title: r.querySelector('[data-hook="review-title"]')?.innerText
              .replace(/^\d\.\d out of 5 stars\n?\s*/, '').trim(),
     stars: parseFloat(r.querySelector(
       '[data-hook="review-star-rating"], [data-hook="cmps-review-star-rating"]')?.innerText) || null,
     date: r.querySelector('[data-hook="review-date"]')?.innerText
             .replace(/^Reviewed in .* on /, '').trim(),
     verified: !!r.querySelector('[data-hook="avp-badge"]'),
     body: r.querySelector('[data-hook="review-body"]')?.innerText.trim(),
   }));
   JSON.stringify({ n: reviews.length, reviews })
   ```

   Amazon's `data-hook` attributes have been stable for years; prefer them
   over classes. Truncate `body` (e.g. `.slice(0, 400)`) when many reviews,
   to keep tool output manageable.

## Gotchas

- **`get_page_text` does NOT see the review list** — it extracts the
  "article" container and Amazon renders reviews in a separate widget.
  Use `javascript_tool` (or `read_page`/`find` as a no-JS fallback).
- **Don't click by screen coordinates** — the page shifts as lazy content
  loads (a stale coordinate once landed on a "Buy Again" tile). Click by
  `ref` from `find`, or better, click in JS as above.
- Review pages **merge all listing variants and generations** under one
  ASIN — check the `Size:`/`Color:` line per review (`format-strip` hook)
  and dates before attributing failures to the current hardware revision.
- The written-review average ≠ headline rating (star-only ratings count
  toward the headline). Report both when summarizing reliability.
- Third-party scraper APIs / MCP servers (Oxylabs, Apify, amazon-mcp-server,
  …) are all limited to the featured sample post-May-2026 and add accounts/
  cost. Not worth it while the Chrome session works.
