# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Local Development (two terminals)
```bash
make install        # npm install frontend deps (once)
make dev-backend    # Terminal 1: PocketBase on :8091, disposable SQLite
make dev-frontend   # Terminal 2: SvelteKit dev server on :5173, proxies /api → :8091
```

### Build & Test
```bash
make build          # Build single Go binary with embedded frontend SPA
make run            # Build + run
make test           # Go tests: go test ./...
make reset          # Wipe local dev database
make clean          # Remove build artifacts
```

### Frontend-only checks (run from `frontend/`)
```bash
npm run check       # Svelte/TypeScript type checking
npm test -- --run   # Vitest unit tests (non-watch)
npm run test:e2e    # Playwright E2E tests
```

### Docker
```bash
make docker         # Build production image
docker compose up --build -d   # Full stack on :8090
```

## Architecture

**Single-binary monolith:** The Go binary embeds the compiled SvelteKit SPA via `embed.FS`. Both backend and frontend are shipped together in one Docker image.

```
Browser → SvelteKit SPA (static, served from Go)
              ↓ fetch /api/*
          PocketBase (Go) — auth, REST API, SQLite, hooks, scheduler
              ↓
          SQLite (/pb_data)
```

### Backend (`internal/`)

Each subdirectory is a domain module registered into PocketBase via hooks and routes:

| Module | Responsibility |
|--------|---------------|
| `account` | Registration, auth, profile, per-user statistics |
| `tips` | Match score predictions; locked at kickoff |
| `forecast` | Tournament-wide predictions (group standings, bracket); locked at tournament start |
| `scoring` | Config-driven point calculation; recomputed on match finalization |
| `leagues` | Private groups with invite codes and leaderboards |
| `sync` | Scheduled polling from API-Football or openfootball for match results |
| `odds` | Bookmaker odds sync (The Odds API); falls back to FIFA rankings |
| `bracket` | Knockout bracket logic and advancement |
| `standings` | Group table and tournament standings |
| `seed` | Idempotent initial data seeding from openfootball dataset |
| `web` | SPA embedding, serving, and metadata (OG tags) |
| `oauth` | Optional Google OAuth |
| `dev` | Dev-mode simulation endpoints (enabled via `WMP_DEV=1`) |
| `clock` | Server time sync |

### Frontend (`frontend/src/`)

SvelteKit in static SPA mode (`@sveltejs/adapter-static` with fallback to `index.html`). Uses Svelte 5.

- `lib/` — Shared logic: PocketBase SDK client, auth store, forecast builder, tips management, multilingual strings, theming
- `routes/` — Pages: home, tips, forecast, leagues, bracket, settings, login/register, dev tools
- `components/` — Reusable UI components (mobile-first, light/dark theme via CSS variables)

### Key Patterns

- **Tips deadline:** Backend enforces that tips are editable only before match kickoff. Frontend reflects this but backend is authoritative.
- **Scoring recomputation:** Scores for all affected users are recomputed whenever a match result is finalized or corrected.
- **League isolation:** Prediction visibility is scoped to league membership.
- **External data sync:** `sync` module polls external APIs on a scheduler; `RESULTS_SOURCE` env var controls the source (`auto|openfootball|apifootball`).
- **Migrations:** PocketBase handles SQLite schema migrations automatically on startup.

## Environment Variables

Copy `.env.example` to `.env`. Key variables:

| Variable | Purpose |
|----------|---------|
| `HTTP_PORT` | Host port (default 8090) |
| `WMP_DEV` | `1` enables dev tools and simulation endpoints |
| `RESULTS_SOURCE` | `auto`, `openfootball`, or `apifootball` |
| `API_FOOTBALL_KEY` | Optional API-Football API key |
| `ODDS_API_KEY` | Optional The Odds API key |
| `PB_ADMIN_EMAIL` / `PB_ADMIN_PASSWORD` | Bootstrap superuser for PocketBase admin UI |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Optional Google OAuth |

PocketBase admin UI is at `/_/` (e.g. `http://localhost:8090/_/`).

## Languages

UI supports Norwegian Bokmål, Nynorsk, and English. Translation strings live in `frontend/src/lib/`.
