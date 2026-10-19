.PHONY: install test migrate run
install:
	pip install -e '.[dev]'
test:
	APP_ENV=test AUTH_MODE=development DATABASE_URL=sqlite:////tmp/vestaai-tests.db python -m pytest -q
migrate:
	alembic upgrade head
run:
	uvicorn app.main:app --reload
