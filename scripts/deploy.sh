#!/usr/bin/env bash
set -Eeuo pipefail
cd "${MENTIFY_DIR:-/opt/mentify}"
: "${BACKEND_TAG:?BACKEND_TAG is required}"
: "${FRONTEND_TAG:?FRONTEND_TAG is required}"
cat > .deploy.env <<EOF
DOCKERHUB_IMAGE=${DOCKERHUB_IMAGE:-holins/mentify-backend}
IMAGE_TAG=${BACKEND_TAG}
FRONTEND_IMAGE=${FRONTEND_IMAGE:-holins/mentify-frontend}
FRONTEND_TAG=${FRONTEND_TAG}
MENTIFY_ENV_FILE=.env.prod
EOF
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml pull
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml up -d --remove-orphans
