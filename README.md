# Mentify Infrastructure

Infrastructure-as-code and deployment configuration for the Mentify educational platform.

This repository is designed for the current cost-conscious academic/demo environment: all application containers run on one AWS EC2 instance, while Amazon S3 is used for object/file storage. The architecture is intentionally simple and affordable, but it is not highly available.

> This repository contains deployment infrastructure only. It does not contain backend Java source code or frontend application code.

## Architecture overview

```text
Users
  |
  | HTTP :80
  v
Caddy reverse proxy on EC2
  |-- /api/*       -> api-gateway:8080
  |-- /actuator/*  -> api-gateway:8080
  |-- /admin*      -> admin-frontend:3000
  |-- /teacher*    -> teacher-frontend:3000
  `-- /student*    -> student-frontend:3000

Private Docker network: mentify-prod_backend
  |
  |-- Frontend containers
  |     |-- admin-frontend
  |     |-- teacher-frontend
  |     `-- student-frontend
  |
  |-- Backend platform services
  |     |-- service-registry
  |     |-- config-server
  |     |-- auth-service
  |     |-- api-gateway
  |     |-- user-service
  |     |-- course-service
  |     |-- entrollment-service
  |     |-- assignment-service
  |     |-- communication-service
  |     |-- attendance-service
  |     |-- exam-service
  |     |-- material-service
  |     |-- calender-service
  |     |-- payment-service
  |     |-- notification-service
  |     |-- analytics-service
  |     `-- ai-service
  |
  `-- Platform dependencies
        |-- PostgreSQL
        |-- Redis
        `-- Kafka

AWS S3
  `-- Object/file storage used by the application
```

Only Caddy is exposed publicly. PostgreSQL, Redis, Kafka, backend services, and frontend containers communicate through the private Docker network.

## Production environment

| Component | Location | Purpose |
|---|---|---|
| AWS EC2 | `13.235.45.255` | Runs the complete Docker deployment |
| Caddy | EC2 container | Public reverse proxy and route dispatcher |
| PostgreSQL 14 | EC2 container and Docker volume | Relational application data |
| Redis 7.4 | EC2 container and Docker volume | Cache, sessions, and temporary data |
| Kafka 3.9.1 | EC2 container and Docker volume | Asynchronous events and messaging |
| Amazon S3 | AWS managed service | File and object storage |
| Docker Hub | External registry | Stores application images |
| GitHub Actions | GitHub | CI/CD and deployment automation |

The runtime deployment directory is:

```text
/opt/mentify
```

The frontend Compose project is located at:

```text
/opt/mentify/frontend
```

The production environment file is stored only on EC2:

```text
/opt/mentify/.env.prod
```

It must have restrictive permissions:

```bash
chmod 600 /opt/mentify/.env.prod
```

Never commit the real production environment file to any repository.

## Microservice responsibilities

### Platform services

- **service-registry**: Eureka service discovery.
- **config-server**: Central Spring configuration service.
- **api-gateway**: Public backend entry point behind Caddy.
- **auth-service**: Login, registration, password handling, and simple JWT issuance.
- **user-service**: User profiles and user administration.

Authentication uses simple JWT with RSA signing. This deployment does not use Keycloak.

### Business services

- **course-service**: Courses and course-related operations.
- **entrollment-service**: Student enrolment workflows.
- **assignment-service**: Assignments and submissions.
- **communication-service**: Communication and messaging features.
- **attendance-service**: Attendance records and operations.
- **exam-service**: Exams, questions, and exam workflows.
- **material-service**: Learning materials and file metadata.
- **calender-service**: Calendar and event operations.
- **payment-service**: Payment-related workflows.
- **notification-service**: User notifications.
- **analytics-service**: Reporting and analytics.
- **ai-service**: AI-assisted application functionality.

Each backend service is packaged in the backend Docker image and started with its service-specific JAR configuration.

## Frontend images

The frontend is a monorepo with three separate Next.js applications and three separate Docker images:

```text
holins/mentify-admin:<git-sha>
holins/mentify-teacher:<git-sha>
holins/mentify-student:<git-sha>
```

Runtime containers:

```text
admin-frontend
teacher-frontend
student-frontend
```

The frontend production build uses:

```text
API base URL: /api
WebSocket base URL: /api/ws
Admin base path: /admin
Teacher base path: /teacher
Student base path: /student
```

There is no generic `holins/mentify-frontend` image.

## Backend image

The backend image is:

```text
holins/mentify-backend:<git-sha>
```

The immutable Git commit tag is preferred for deployment. The `latest` tag may also be published for convenience, but production deployment should use the commit SHA.

## Amazon S3 storage

S3 is used for application files and objects instead of storing uploaded files permanently inside the EC2 container filesystem.

Typical S3 responsibilities include:

- uploaded learning materials;
- assignment or submission attachments;
- communication attachments;
- generated or processed files;
- other application-managed objects.

The application should use an IAM role attached to the EC2 instance where possible. If access keys are unavoidable, they must be stored as GitHub/EC2 secrets and never committed.

S3 operational requirements:

- keep buckets private by default;
- use least-privilege IAM permissions;
- enable encryption;
- configure lifecycle rules for temporary objects;
- monitor storage, request, and data-transfer costs;
- back up or version important objects where required;
- never expose long-lived AWS credentials in Docker images or logs.

## Docker networking rules

All services use the Docker network:

```text
mentify-prod_backend
```

Container-to-container communication must use Docker service names:

```text
postgres
redis
kafka
auth-service
user-service
api-gateway
```

Do not use `localhost` for another container. Inside a container, `localhost` refers only to that same container.

Examples:

```text
PostgreSQL host: postgres
Redis host: redis
Kafka host: kafka:29092
Auth service: http://auth-service:8085
User service: http://user-service:8081
```

## Deployment ownership

### Backend repository

The backend repository owns:

- backend source code;
- backend tests;
- backend Docker image build;
- backend image publishing;
- backend application deployment.

Merging backend changes into `main` triggers the backend CI/CD workflow when its workflow checks pass.

### Frontend repository

The frontend repository owns:

- admin, teacher, and student source code;
- frontend tests;
- three frontend Docker image builds;
- frontend image publishing;
- frontend container deployment.

Merging frontend changes into `main` triggers:

1. formatting checks;
2. linting for all three applications;
3. application builds;
4. Playwright tests;
5. Docker image builds;
6. Docker Hub publishing;
7. EC2 frontend deployment;
8. route verification for `/admin/`, `/teacher/`, and `/student/`.

### Infra repository

This repository owns:

- backend Docker Compose configuration;
- Caddy configuration;
- deployment scripts;
- health checks;
- rollback documentation;
- EC2 operational documentation.

Infra changes do not rebuild backend or frontend application images. They deploy infrastructure configuration only.

## CI/CD flow

### Application change

```text
Developer branch
  -> Pull request
  -> Merge into main
  -> Tests and quality checks
  -> Build application image
  -> Push image to Docker Hub
  -> SSH to EC2
  -> Docker Compose pull
  -> Recreate affected containers
  -> Health and route verification
```

### Infrastructure change

```text
Infra development branch
  -> Pull request
  -> Merge into main
  -> Infra workflow/manual deployment
  -> Copy Compose and Caddy files to EC2
  -> Pull backend image selected by the deployment tag
  -> Apply infrastructure configuration
  -> Verify actuator health
```

The current infra workflows support manual execution and repository-dispatch execution. They do not build frontend images and do not reference a generic frontend image.

## Required GitHub secrets

Configure secrets in each repository that runs a deployment workflow:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
EC2_HOST
EC2_USERNAME
EC2_SSH_PRIVATE_KEY
```

Current values conceptually are:

```text
EC2_HOST: 13.235.45.255
EC2_USERNAME: ubuntu
```

`EC2_SSH_PRIVATE_KEY` must contain the complete private key contents. Do not print it in logs or commit it.

The real production application values remain on EC2 in `/opt/mentify/.env.prod`.

## Security Group

Recommended public inbound access:

| Port | Source | Purpose |
|---|---|---|
| 80/TCP | `0.0.0.0/0` | Public HTTP through Caddy |
| 22/TCP | Trusted administrator IP only | SSH administration |

Do not expose PostgreSQL, Redis, Kafka, Eureka, Config Server, or individual microservice ports publicly.

## Health checks

Backend health:

```bash
curl http://13.235.45.255/actuator/health
```

Expected result:

```json
{"status":"UP"}
```

Frontend checks:

```bash
curl -I http://13.235.45.255/admin/
curl -I http://13.235.45.255/teacher/
curl -I http://13.235.45.255/student/
```

EC2 container checks:

```bash
cd /opt/mentify

docker compose \
  --env-file .env.prod \
  --env-file .deploy.env \
  -f docker-compose.prod.yml ps

cd /opt/mentify/frontend

docker compose -f docker-compose.prod.yml ps
```

## Cost-conscious design and limitations

This deployment uses one EC2 instance because the project has a limited budget. This provides:

- one server to manage;
- no separate load balancer cost;
- no separate Kubernetes/ECS control-plane complexity;
- simple Docker Compose operations;
- S3 storage without keeping large files on the EC2 disk.

The trade-offs are:

- the EC2 instance is a single point of failure;
- all microservices compete for the same CPU and memory;
- PostgreSQL, Redis, and Kafka are not highly available;
- a host failure can affect the entire platform;
- Docker volumes require a backup plan;
- public HTTP is not suitable for sensitive production use;
- S3 and network usage can still create AWS charges;
- free-tier eligibility depends on the AWS account, instance type, region, and usage.

For a future full production architecture, move stateful services to managed PostgreSQL, Redis, and Kafka, run containers on ECS or EKS, use HTTPS with a domain and ACM, and add monitoring, backups, and high availability.

## Operational safety

Do not run:

```bash
docker compose down -v
```

because it can delete persistent database data.

Before changing infrastructure:

1. Confirm the target EC2 host.
2. Confirm the image tag.
3. Back up important PostgreSQL and S3 data.
4. Check disk, memory, and swap usage.
5. Apply one controlled change.
6. Verify backend and frontend routes.
7. Review container logs if a health check fails.

Useful commands:

```bash
free -h
df -h
docker system df

docker compose \
  --env-file .env.prod \
  --env-file .deploy.env \
  -f docker-compose.prod.yml \
  logs --tail=100 api-gateway

docker compose -f /opt/mentify/frontend/docker-compose.prod.yml logs --tail=100 admin-frontend
```

## Repository structure

```text
.
|-- .github/workflows/
|   |-- deploy-production.yml
|   `-- deploy-staging.yml
|-- docker-compose.prod.yml
|-- Caddyfile
|-- environments/
|   |-- .env.example
|   `-- .deploy.env.example
|-- scripts/
|   |-- deploy.sh
|   |-- health-check.sh
|   `-- rollback.sh
|-- docker/postgres/init/
|   `-- 01-create-service-databases.sh
|-- docs/
|   |-- architecture.md
|   |-- deployment-runbook.md
|   `-- adr-001-single-ec2.md
`-- README.md
```

## Related documentation

- [Architecture](docs/architecture.md)
- [Deployment runbook](docs/deployment-runbook.md)
- [ADR-001: Single EC2 deployment](docs/adr-001-single-ec2.md)
