# Architecture

Internet -> EC2 port 80 -> Caddy.

Caddy routes:
- /api/* and /actuator/* -> api-gateway:8080
- all other paths -> frontend:80

All services share the private Docker network backend. Container-to-container addresses must use service names such as postgres, redis, kafka, auth-service, and user-service; localhost is only for a process inside the same container.

This single-EC2 design is the current staging/demo architecture. It has no high availability. PostgreSQL and Redis backups, disk monitoring, memory monitoring, and Security Group maintenance are required. A future production design can move stateful services to managed AWS services and run workloads on ECS/EKS.
