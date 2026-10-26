# Deployment Runbook

## EC2 prerequisites

- Docker and Compose installed
- The backend network `mentify-prod_backend` exists
- `/opt/mentify/.env.prod` exists with mode 600
- `/opt/mentify/frontend/docker-compose.prod.yml` exists or is copied by the frontend workflow
- Docker Hub and EC2 GitHub secrets configured
- Port 80 open; SSH restricted to a trusted IP

## Frontend production deployment

Merge the frontend pull request into `main`. The frontend workflow then:

1. Installs root and application dependencies.
2. Checks formatting.
3. Runs lint and production builds for admin, teacher, and student.
4. Runs Playwright browser tests.
5. Builds and pushes three immutable Docker images.
6. Copies the frontend Compose file to `/opt/mentify/frontend`.
7. Logs in to Docker Hub on EC2.
8. Pulls the commit-tagged images and force-recreates the containers.
9. Verifies `/admin/`, `/teacher/`, and `/student/` return HTTP 200.

## Backend/infrastructure deployment

Run the infra GitHub Actions deployment only when the backend image/tag or infrastructure files need to change. It copies the backend Compose file and Caddyfile to `/opt/mentify`, then checks `/actuator/health`.

The infra workflow must not replace the frontend Compose project or use a single generic frontend image. The three frontend services are deployed by the frontend repository workflow.

## Manual checks

```bash
cd /opt/mentify
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml ps
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml logs --tail=100 api-gateway
cd /opt/mentify/frontend
docker compose -f docker-compose.prod.yml ps
curl -i http://127.0.0.1/actuator/health
curl -I http://127.0.0.1/admin/
curl -I http://127.0.0.1/teacher/
curl -I http://127.0.0.1/student/
```

## Rollback frontend

Set `IMAGE_TAG` to the previous frontend commit SHA and recreate:

```bash
cd /opt/mentify/frontend
export IMAGE_TAG=<previous-frontend-sha>
export ADMIN_IMAGE=holins/mentify-admin
export TEACHER_IMAGE=holins/mentify-teacher
export STUDENT_IMAGE=holins/mentify-student
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --force-recreate
```

## Rollback backend

```bash
cd /opt/mentify
cp .deploy.env.previous .deploy.env
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml pull
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml up -d --remove-orphans
```

Never use `down -v`; it can delete persistent database data.
