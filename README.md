# VestaAI Backend v0.3

Secure MVP backend for VestaAI, the AI growth copilot for mobile app founders. This version provides workspace-aware authentication, app management, manual metric ingestion, deterministic evidence-based growth briefings, recommendation review, and audit events. External analytics providers and live LLM calls are not connected yet; the analyst and briefing workflow uses explicit rules and reports its analysis mode to clients.

## Stack

- Python 3.11+
- FastAPI and Pydantic
- SQLAlchemy 2 + PostgreSQL
- Alembic schema migrations
- Supabase JWT verification (ES256/RS256 asymmetric signing keys)

## Local setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
cp .env.example .env
# Set DATABASE_URL to a local PostgreSQL database.
alembic upgrade head
uvicorn app.main:app --reload
```

API docs are at `/docs`; `GET /health` is a process health probe and `GET /ready` checks database connectivity. Never expose local development authentication to the public internet.

## Authentication and production safety

Local development defaults to `APP_ENV=development` and `AUTH_MODE=development`; this uses one fixed local identity and is only for a local, non-public environment. Production startup rejects development auth. Production configuration requires `APP_ENV=production`, `AUTH_MODE=supabase`, `SUPABASE_URL`, `SUPABASE_JWT_ISSUER`, and an explicit non-wildcard `CORS_ORIGINS` allowlist. JWT signature, algorithm, issuer, audience, expiry, issue time and subject are validated. Supabase asymmetric ES256/RS256 signing keys are required.

The first authenticated request creates a local user profile keyed by the verified JWT `sub`. `X-Workspace-ID` selects a workspace but never grants access: the backend verifies active membership on each workspace-scoped request. Only owners/admins can create apps, ingest metrics, generate briefings, or approve/dismiss recommendations. Decision records include the acting user and are not connected to any external campaign execution.

## API workflows

1. `GET /api/v1/me` — create/read authenticated profile.
2. `POST /api/v1/workspaces` — create workspace and owner membership atomically.
3. `GET /api/v1/workspaces` — list active memberships.
4. `POST /api/v1/apps` — create an app in the selected workspace.
5. `GET /api/v1/apps` — list apps in the selected workspace.
6. `POST /api/v1/apps/{app_id}/metrics` — ingest a verified metric observation. A metric definition is created when first needed. Duplicate app/metric/period/source combinations return 409.
7. `GET /api/v1/dashboard/summary` and `GET /api/v1/metrics?metric_key=downloads&days=14` — read metric data.
8. `POST /api/v1/briefings/generate?app_id={uuid}` — generate a 14-day evidence-based briefing and reviewable recommendations for changes of at least 20%.
9. `POST /api/v1/analyst/ask` — summarize observed changes, cite available metric values and periods, and label possible causes as hypotheses. This is deterministic analysis, not an LLM response.
10. `GET /api/v1/recommendations`, `POST /api/v1/recommendations/{id}/approve`, `POST /api/v1/recommendations/{id}/dismiss` — review recommendations. Approval only changes VestaAI's internal status; it does not execute an external action.
11. `GET /api/v1/briefings/latest` and `GET /api/v1/integrations` — inspect generated briefing and integration status.

Tenant endpoints require both `Authorization: Bearer <Supabase access token>` and `X-Workspace-ID: <workspace UUID>` in production. The local development auth mode does not require a bearer token and must remain local-only.

## Database migrations

Alembic is the schema source of truth. The initial migration now uses explicit `op.create_table` / `op.create_index` operations and a scoped reverse-order downgrade; it does not call `Base.metadata.create_all()` or `drop_all()`. Run `alembic upgrade head` as a release step. The initial migration is intended for new deployments; if an existing database has already stamped this revision, back up and reconcile schema state before changing migration history.

## Tests

```bash
APP_ENV=test AUTH_MODE=development DATABASE_URL=sqlite:////tmp/vestaai-tests.db python -m pytest -q
```

The unit/API suite uses SQLite for fast deterministic tests. To run the PostgreSQL integration smoke test against a disposable database whose schema has already been migrated:

```bash
TEST_DATABASE_URL='postgresql+psycopg://USER:PASSWORD@HOST:5432/TEST_DB' python -m pytest -m postgres -q
```

Do not point the integration test at production. `TEST_DATABASE_URL` is optional; without it the PostgreSQL smoke test is skipped.

## Not yet production complete

- No real analytics provider adapter or scheduled sync worker is connected.
- No external LLM is called; insights are rule-based and intentionally conservative.
- Before production, run the suite against a real disposable PostgreSQL instance, configure Supabase and CORS, add rate limiting and operational monitoring, configure backups, and complete a deployment-specific secret review.
