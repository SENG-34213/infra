# Mentify Infrastructure

Central deployment infrastructure for Mentify. This repository owns Docker Compose, Caddy, EC2 deployment workflows, health checks, rollback scripts, and operational documentation.

Application repositories remain unchanged:
- backend: source, tests, and backend image build
- frontend: source, tests, and frontend image build
- infra: deployment orchestration
- tests: integration and end-to-end tests
- documents: SRS, SDS, ADRs, and reports

## Runtime

One Ubuntu EC2 instance runs PostgreSQL, Redis, Kafka, Eureka, Config Server, authentication, backend services, frontend, and Caddy on a private Docker network. Only Caddy is public.

Images are immutable:
- holins/mentify-backend:<git-sha>
- holins/mentify-frontend:<git-sha>

The frontend image is expected to serve HTTP on port 80. The existing frontend repository is not modified by this repository.

## GitHub configuration

Secrets: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, EC2_HOST, EC2_USERNAME, EC2_SSH_PRIVATE_KEY.

Variables: DOCKERHUB_IMAGE (default holins/mentify-backend), FRONTEND_IMAGE (default holins/mentify-frontend).

Create a protected GitHub Environment named production with required reviewers.

See docs/deployment-runbook.md.
