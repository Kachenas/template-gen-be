# Database Access (via SSM Bastion)

RDS is not publicly accessible. Reach it by tunneling through the SSM-managed bastion — no SSH key, no open inbound ports, access is controlled entirely by IAM (the `staging-sample-backend-developers` IAM group).

## Prerequisites

- AWS CLI v2 with the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) installed
- Your IAM user added to the `staging-sample-backend-developers` group (`terraform.tfvars` → `developer_user_names`, or added manually)

## Start a tunnel

```bash
aws ssm start-session \
  --target <bastion-instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["5433"]}' \
  --region ap-southeast-1
```

Get `<bastion-instance-id>` from `terraform output bastion_instance_id` (or the AWS console), and `<rds-endpoint>` from `terraform output db_endpoint`, both run from `sample-backend-infrastructure/terraform/environments/staging`.

## Connect

```bash
psql "host=127.0.0.1 port=5433 dbname=sample user=sample_admin sslmode=require"
```

Get the real password from Secrets Manager (`staging-sample-backend` secret, key `DB_PASSWORD`) — never commit it, and never put it in `terraform.tfvars` in plaintext for anything beyond local one-off testing.

## Why can't I connect directly?

The RDS security group only allows inbound PostgreSQL from the ECS security group and the bastion security group — by design, so the database is never reachable from the open internet even by accident.
