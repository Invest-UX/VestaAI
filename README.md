# VestaAI backend v0.2 — database, auth and workspace isolation

Brand stays VestaAI: Midnight Navy `#0B1F3B`, Electric Mint `#22E3A8`, White `#FFFFFF`, Slate Grey `#6B7280`. This milestone deliberately does not connect analytics providers or execute campaigns.

## Local setup
1. Python 3.11+ and PostgreSQL 15+ required.
2. `python -m venv .venv && source .venv/bin/activate`
3. `pip install -e ".[dev]"`
4. Copy `.env.example` to `.env`; configure `DATABASE_URL` and create the database.
5. Run `alembic upgrade head`, then `uvicorn app.main:app --reload`.
6. API docs at `/docs`; `GET /health` and `GET /ready` are service and database probes.

## Authentication
Local-only: `AUTH_MODE=development` and `APP_ENV=development`. This uses a fixed local identity and MUST NOT be exposed publicly.
Production: set `AUTH_MODE=supabase`, `SUPABASE_URL=https://PROJECT.supabase.co`, and `SUPABASE_JWT_ISSUER=https://PROJECT.supabase.co/auth/v1`. JWT signature is verified against Supabase JWKS; issuer, audience and expiry are checked. This supports asymmetric ES256/RS256 JWT keys. Configure an asymmetric Supabase signing key; legacy shared-secret tokens are intentionally not accepted here. The first authenticated request creates a local profile keyed to verified `sub`.

## Workspace isolation
`X-Workspace-ID` is a selector, not authorization. Every tenant route must depend on `require_workspace_membership`; that helper validates UUID and verifies active membership in PostgreSQL. Workspace creation and owner membership are committed in one transaction. For tenant resources, always filter by both resource ID and `workspace_id`. Never use client-supplied IDs alone. Roles currently: owner/admin/member/viewer; add per-action role policy before inviting team members or adding destructive operations.

## Endpoints
- `GET /api/v1/me`
- `GET /api/v1/workspaces` (only current user's active memberships)
- `POST /api/v1/workspaces` with `{ "name": "My App Studio", "slug": "my-app-studio", "timezone": "Africa/Lagos" }`
- `GET /api/v1/workspaces/current` with `X-Workspace-ID`
- Existing prototype route skeletons remain mounted under `/api/v1`.

Frontend example:
```js
fetch(`${API_BASE_URL}/workspaces/current`, {
  headers: { Authorization: `Bearer ${supabaseAccessToken}`, "X-Workspace-ID": selectedWorkspaceId }
});
```
The browser should list workspaces after login, prompt to create one if none exist, then select one in UI state. The API checks membership on every tenant-scoped request regardless of browser state.

## Database migrations
Alembic migrations are the source of truth. Run `alembic upgrade head`; don't rely on automatic `create_all` for deployed environments. The initial migration creates the complete schema already present in this repository.

## Before deployment
Set production environment and Supabase auth; restrict CORS; keep DB credentials in a secret manager; run migrations as a release step; add PostgreSQL integration tests, rate limiting, backups, monitoring and structured logs with token redaction. Do not expose local development auth in any shared environment.
