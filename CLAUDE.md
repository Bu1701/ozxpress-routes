# ozxpress-routes — Claude Code Standing Rules

## Project Overview
Manhattan B2B sales route builder for oz-xpress × FOXinGREEN.
Single-page app that uses the Anthropic Claude API (via a Netlify function proxy) to generate timed stop-by-stop sales routes for NYC neighborhoods.

## Environments

| | Live |
|---|---|
| Netlify Site | ozxpress-routes.netlify.app |
| GitHub Repo | https://github.com/leifenberg/foxb2b |
| Netlify Account | mike-dtt479k's team |
| Supabase Project | Ozxpress-routes (ref `bxlpoxqckfrikvjhbcju`, us-east-1, GL&S org) |

Deploys automatically from GitHub (master branch).

## Supabase Backend (added 2026-06-28)
- **URL:** `https://bxlpoxqckfrikvjhbcju.supabase.co`
- **anon key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4bHBveHFja2ZyaWt2amhiY2p1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2ODEyMzgsImV4cCI6MjA5ODI1NzIzOH0.Jrcxy3J-BL3hOat5fzPoq-XHYYJABgRhjhOQDCBILjw` (public, RLS-protected, safe to commit)
- **service_role / secret key:** held by Mike — goes into Netlify env vars only (NEVER in client code). Needed when we build server-side rep creation + email functions.
- Schema lives in `db-schema.sql` (run via Supabase SQL Editor). Tables: `reps`, `businesses`, `appointments`, `routes`.
- Auth: Supabase Auth email+password. Roles: `admin` vs `salesperson` (stored on `reps.role`). RLS enforces per-rep data isolation; admin sees all.
- NOTE: `claude.js` already uses a server-side `ANTHROPIC_API_KEY` env var — salespeople do NOT need their own API key.

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
Reps are now managed in Supabase (the `reps` table) via the Back Office (admin.html), not placeholder names. Auth-backed (each rep is a Supabase auth user). Old localStorage rep system is removed.

## Multi-User Build — Phase Status (started 2026-06-28)
Turning the app into a multi-user system: per-salesperson logins, territory ownership, back office, email. 4 phases.

- ✅ **Phase 1 — Auth foundation: DONE + LIVE (2026-06-28, commit 7d43a40).**
  login.html (sign-in) → routes admin to admin.html, salesperson to index.html. supabase-client.js = shared auth (`requireAuth`, `signIn`, `signOut`). index.html gated; salesperson locked to own identity (no rep picker), admin picks any rep; identity + logout in sidebar. admin.html rebuilt as Back Office (admin-only): lists reps from Supabase + Add Rep form. create-rep.js Netlify function = admin-verified server-side user creation. Admin login = **mike@foxingreen.com**.
  - ⏳ **LAST STEP TO FINISH PHASE 1:** set env var `SUPABASE_SERVICE_KEY` (= Supabase service_role secret) on the Netlify ozxpress-routes site, then redeploy. Until then "Add Rep" errors with "Server not configured…" (by design — function degrades gracefully). After setting it: create a test salesperson + verify the salesperson login path.
- ⬜ **Phase 2 — Territory ownership:** generating a route saves the businesses to `businesses` table stamped `claimed_by` = the rep; other reps never see claimed spots in that neighborhood; dedup against existing claims. LOCKED RULE: claimed on GENERATE; admin releases unvisited ones back.
- ⬜ **Phase 3 — Back office dashboard:** admin sees all reps + all appointments/visits + who owns what; reassign/release.
- ⬜ **Phase 4 — Business info + email:** reps add notes/contacts per business; email businesses (Netlify function + SendGrid).

Full plan + decisions in the [[project_ozxpress_backend]] memory.

## Older Open Items
- 🟢 Replace Rep 1–5 — DONE (reps now in Supabase via Back Office)
- 🟢 Copy route — DONE (Copy Route button shipped earlier)
- 🟢 Map view — DONE (walking directions + numbered markers)
- 🟡 Persist generated routes — folds into Phase 2 (routes table exists)
- 🟡 Custom domain setup

## Git Workflow (Standing Rules)
- **No branches** — always work on master only
- **Session start:** `git pull` before touching any file
- **Session end:** review all changes, then `git add .` → `git commit -m "message"` → `git push`
- Netlify auto-deploys from master — live in ~30 seconds

## Dual-Push Setup (IMPORTANT)
Every `git push` goes to **two remotes simultaneously**:
1. `leifenberg/foxb2b` — the main repo (leifenberg is the owner, Bu1701 is collaborator)
2. `Bu1701/ozxpress-routes` — Netlify is connected to this repo and auto-deploys from it

This is already configured in the local git remotes — a single `git push` handles both.
Do NOT change the remote setup.

## Session Start Checklist
1. Read this CLAUDE.md — you are now fully briefed
2. `git pull` — get latest before starting
3. Ask what we are working on today
