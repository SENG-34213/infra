# Architecture

Internet -> EC2 port 80 -> Caddy.

Caddy routes:
- /api/* and /actuator/* -> api-gateway:8080
- /admin* -> admin-frontend:3000
- /teacher* -> teacher-frontend:3000
- /student* -> student-frontend:3000

The backend Compose project and the frontend Compose project share the external Docker network `mentify-prod_backend`. Container-to-container addresses must use service names such as postgres, redis, kafka, auth-service, user-service, admin-frontend, teacher-frontend, and student-frontend. `localhost` is only for a process inside the same container.

Frontend applications use `/api` and `/api/ws` in production; they must not use localhost or a development port.

This single-EC2 design is the current staging/demo architecture. It has no high availability. PostgreSQL and Redis backups, disk monitoring, memory monitoring, and Security Group maintenance are required. A future production design can move stateful services to managed AWS services and run workloads on ECS/EKS.
