# Infrastructure

AWS infrastructure for **sample-backend** (Laravel), provisioned with Terraform and deployed via GitHub Actions to ECS Fargate.

## Environments

| Environment | Branch | AWS account | Region |
|---|---|---|---|
| staging | `staging` | (single account, shared with any future production env) | `ap-southeast-1` |

Production was not generated in this pass — re-run the `setup-aws-infra` skill (or copy `environments/staging` to `environments/production`) when it's needed.

## Components

- **VPC**: 2 public + 2 private subnets across 2 AZs, single NAT gateway
- **ALB**: public-facing, HTTP listener on port 80, forwards to the ECS target group, health check `/up`
- **ECS Fargate**: cluster `staging-sample-backend`, 1 task (256 CPU / 512 MB), rolling deploys with circuit-breaker rollback
- **ECR**: repository `staging-sample-backend`, untagged images expire after 7 days, only the 10 most recent tagged images kept
- **RDS PostgreSQL**: `db.t3.micro`, private subnets only, reachable from ECS tasks and the bastion
- **Bastion**: SSM-managed EC2 instance for developer DB tunneling — no inbound rules, no SSH key, access is via `aws ssm start-session`
- **Secrets Manager**: one secret (`staging-sample-backend`) holding `APP_KEY` and `DB_*` values, injected into the ECS task as `secrets`
- **GitHub Actions OIDC**: the deploy role is assumed via OIDC, no long-lived AWS keys stored in GitHub

## Directory layout

```
sample-backend-infrastructure/terraform/
  modules/            # networking, security-groups, ecr, secrets, iam, alb, rds, bastion, iam-developers, ecs
  environments/
    staging/          # main.tf wires the modules together, variables.tf, outputs.tf
.github/workflows/
  terraform-staging.yml   # plan (PR) / apply (push to staging) / plan|apply|destroy (workflow_dispatch)
  deploy-staging.yml      # lint + test -> build & push image -> deploy to ECS
Dockerfile                # multi-stage: base -> vendor (composer install) -> production (nginx + php-fpm + supervisord)
```

## Deploy flow

1. Push to `staging` touching only app code → `deploy-staging.yml` runs lint, tests, builds/pushes the image to ECR, then updates the ECS service.
2. Push to `staging` touching `sample-backend-infrastructure/terraform/**` → `terraform-staging.yml` applies the Terraform change. App deploys and infra applies never race each other (each workflow's path filter excludes the other's files).
3. Opening a PR against `staging` that touches Terraform posts a plan as a PR comment; merging (the resulting push) auto-applies.

See `docs/AWS-FAQ.md` for setup/troubleshooting and `docs/database-access.md` for connecting to RDS through the bastion.
