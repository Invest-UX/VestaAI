# VestaAI Security Review — v0.3

## Changes implemented

- Production configuration fails closed unless Supabase auth is enabled and Supabase URL/issuer are configured; wildcard CORS is rejected in production.
- Development authentication is rejected outside development/test/local environments.
- Workspace-scoped routes validate active membership; app creation, metric ingestion, briefing generation, and recommendation approval/dismissal require owner/admin roles.
- Cross-workspace app IDs are queried together with the authorized workspace ID.
- Recommendation review records the acting user on both the recommendation and approval event, with an audit event noting that no external action was executed.
- JWT verification restricts asymmetric algorithms to ES256/RS256 and validates signature, issuer, audience, expiration, issue time, and subject.
- The initial migration uses explicit Alembic table/index operations and drops only its own tables in reverse dependency order.
- Workspace roles/status and recommendation status/priority are constrained at the database level.
- Added metric ingestion with duplicate detection, app management, evidence-backed deterministic briefings, and analyst responses that distinguish observations from hypotheses.

## Important residual risks

- The PostgreSQL integration test was not run against a live PostgreSQL instance in this environment. SQLite tests do not prove PostgreSQL-specific behavior.
- Analytics provider integrations, secure credential storage/rotation, scheduled sync, rate limiting, production observability, backup/restore drills, and a real LLM integration remain future work.
- `secret_reference` is a reference field, not a secret manager. Never store raw provider tokens there.
- Manual metric ingestion currently allows owners/admins to submit observations; production provider ingestion should use authenticated provider callbacks/jobs and stronger idempotency controls.
- The rules engine flags large changes but cannot infer causality from aggregate metrics alone. Its outputs must remain hypotheses until segmented evidence supports them.
- The initial migration is suitable for a new database. Existing deployed databases require a reviewed migration plan rather than rewriting applied history.

## Deployment checklist

- Set `APP_ENV=production`, `AUTH_MODE=supabase`, `SUPABASE_URL`, `SUPABASE_JWT_ISSUER`, `SUPABASE_JWT_AUDIENCE`, `DATABASE_URL`, and exact `CORS_ORIGINS`.
- Use a least-privilege database role and a secrets manager; never commit `.env`.
- Run migrations as a release job; do not run schema creation automatically on application startup.
- Verify role matrix, cross-workspace access, JWT failure cases, and PostgreSQL migration behavior in CI.
- Add rate limits to auth-sensitive and write endpoints, structured redacted logs, alerts, backups, and restore testing.
