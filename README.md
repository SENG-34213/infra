# Mentify Infrastructure

Central deployment infrastructure for Mentify. This repository owns backend Docker Compose, Caddy, EC2 deployment workflows, health checks, rollback scripts, and operational documentation.

Application repositories remain unchanged in their application code:
- backend: source, tests, and backend image build
- frontend: source, tests, and the three frontend image builds
- infra: deployment orchestration and reverse-proxy configuration
- tests: integration and end-to-end tests
- documents: SRS, SDS, ADRs, and reports

## Runtime

One Ubuntu EC2 instance runs PostgreSQL, Redis, Kafka, Eureka, Config Server, authentication, backend services, the three frontend containers, and Caddy on the private Docker network `mentify-prod_backend`. Only Caddy is public.

Frontend images:
- holins/mentify-admin:<git-sha>
- holins/mentify-teacher:<git-sha>
- holins/mentify-student:<git-sha>

Backend images use:
- holins/mentify-backend:<git-sha>

The frontend repository deploy workflow owns `/opt/mentify/frontend/docker-compose.prod.yml` and recreates the three frontend containers. This repository owns the Caddy routing used by both stacks.

## GitHub configuration

Secrets: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, EC2_HOST, EC2_USERNAME, EC2_SSH_PRIVATE_KEY.

Variables: DOCKERHUB_IMAGE (default holins/mentify-backend).

Create a protected GitHub Environment named production with required reviewers.

See docs/deployment-runbook.md.
