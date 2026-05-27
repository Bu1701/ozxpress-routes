# ozxpress-routes — Claude Code Standing Rules

## Project Overview
Manhattan B2B sales route builder for oz-xpress × FOXinGREEN.
Single-page app that uses the Anthropic Claude API (via a Netlify function proxy) to generate timed stop-by-stop sales routes for NYC neighborhoods.

## Environments

| | Live |
|---|---|
| Netlify Site | ozxpress-routes.netlify.app |
| GitHub Repo | https://github.com/Bu1701/ozxpress-routes |
| Netlify Account | mike-dtt479k's team |

Deploys automatically from GitHub (master branch).

## Folder Structure
```
D:\ozxpress-routes\
├── CLAUDE.md                          ← this file
├── index.html                         ← main single-page app
├── netlify.toml                       ← Netlify config + CSP headers
└── netlify/
    └── functions/
        └── claude.js                  ← Anthropic API proxy (passes x-api-key from client)
```

## How It Works
- User enters their Anthropic API key in the sidebar (saved to localStorage)
- Selects neighborhood, sales rep, start time, number of stops (5–10)
- Clicks Generate → POST to `/.netlify/functions/claude` with key in `x-api-key` header
- Netlify function forwards request to Anthropic API and returns response
- App parses JSON array of stops and renders timed cards (25 min per stop)

## API Proxy (claude.js)
- Validates `x-api-key` starts with `sk-ant-`
- Forwards raw request body to `https://api.anthropic.com/v1/messages`
- No server-side API key — user supplies their own key from the browser

## Design System
- Background: `#0e0f0d`
- Green accent: `#b8f04a`
- Fonts: DM Mono (code/labels) + DM Sans (body) from Google Fonts
- Tier 1 = furniture/appliance/mattress (green badge)
- Tier 2 = thrift/decor/medical (blue badge)

## Neighborhoods Available
SoHo/NoLita, Lower East Side/Canal St, Chelsea, Flatiron/Union Square,
Upper East Side, Upper West Side, Midtown, Harlem, Washington Heights,
TriBeCa/Financial District, East Village/Alphabet City, West Village/Greenwich Village

## Sales Reps
Rep 1–5 (placeholder names — to be updated with real names)

## Open Items
- 🟡 Replace Rep 1–5 with real sales rep names
- 🟡 Add "Copy route" / export to PDF or email feature
- 🟡 Add map view of the route stops
- 🟡 Persist generated routes (localStorage or Supabase)
- 🟡 Custom domain setup

## Deploy Process
1. Edit files in `D:\ozxpress-routes\`
2. `git add .` → `git commit -m "message"` → `git push`
3. Netlify auto-deploys from master branch — live in ~30 seconds

## Session Start Checklist
1. Read this CLAUDE.md — you are now fully briefed
2. Ask what we are working on today
