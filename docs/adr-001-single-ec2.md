# ADR-001: Single EC2 deployment

Status: Accepted for the current academic staging/demo environment.

We run Mentify on one Ubuntu EC2 instance using Docker Compose and Caddy because it fits the free-tier constraint and supports a live deployed demonstration. The trade-off is that one host failure affects the whole application and the stateful services require backups.

Future production migration: managed PostgreSQL/Redis/Kafka plus ECS or EKS.
