# Deployment Runbook

## EC2 prerequisites

- Docker and Compose installed
- /opt/mentify/.env.prod exists with mode 600
- Docker Hub and EC2 GitHub secrets configured
- Port 80 open; SSH restricted to a trusted IP

## Staging

Run GitHub Actions -> Deploy staging on development and provide backend_tag and frontend_tag. The workflow copies Compose, Caddy, and .deploy.env. It never copies the real .env.prod.

## Production

Run Deploy production on main. The production GitHub Environment must require manual approval. The workflow saves .deploy.env.previous, pulls immutable tags, starts the stack, and checks /actuator/health.

## Manual checks

```bash
cd /opt/mentify
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml ps
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml logs --tail=100 api-gateway
curl -i http://127.0.0.1/actuator/health
```

## Rollback

```bash
cd /opt/mentify
cp .deploy.env.previous .deploy.env
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml pull
docker compose --env-file .env.prod --env-file .deploy.env -f docker-compose.prod.yml up -d --remove-orphans
```

Never use down -v because it can delete persistent database data.
