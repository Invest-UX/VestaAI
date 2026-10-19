# VestaAI Backend v0.3 — Test Results

## Executed in this environment

- `python -m compileall -q app tests alembic` — **PASS**.
- `APP_ENV=test AUTH_MODE=development DATABASE_URL=sqlite:////tmp/vestaai-test-import.db python -m pytest -q` — **13 passed, 1 skipped**.
- `APP_ENV=test AUTH_MODE=development DATABASE_URL=sqlite:////tmp/vestaai-migration.db alembic upgrade head` — **PASS** on SQLite test database.
- `APP_ENV=test AUTH_MODE=development DATABASE_URL=sqlite:////tmp/vestaai-migration.db alembic downgrade base` — **PASS** on SQLite test database.
- Re-ran `alembic upgrade head` after downgrade — **PASS**.

## Covered tests

- Workspace membership isolation (foreign workspace hidden).
- Viewer denied app creation.
- Owner can create an app.
- Viewer denied recommendation approval.
- Owner approval records the actor.
- Cross-workspace app ID cannot be used for metric ingestion.
- Metric ingestion and evidence-based briefing generation.
- JWT wrong issuer rejected.
- Expired JWT rejected.
- Valid asymmetric RS256 JWT accepted.
- Production configuration rejects development authentication and wildcard CORS; production Supabase URLs must use HTTPS.
- Existing health endpoint test.

## Skipped / not verified

- PostgreSQL integration smoke test — **SKIPPED**, because `TEST_DATABASE_URL` was not configured. No live PostgreSQL server was tested.
- No live Supabase tenant/JWKS endpoint was called.
- No real analytics provider or LLM integration was tested.
- No browser end-to-end test against the frontend was run.

SQLite results validate basic route/model behavior only. They are not a substitute for PostgreSQL integration verification.
