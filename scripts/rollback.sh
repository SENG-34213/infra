#!/usr/bin/env bash
set -Eeuo pipefail
cd "${MENTIFY_DIR:-/opt/mentify}"
test -f .deploy.env.previous
cp .deploy.env.previous .deploy.env
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml pull
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml up -d --remove-orphans
