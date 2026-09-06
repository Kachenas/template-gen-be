# AWS Setup FAQ

## What do I need to do before the first `terraform apply`?

1. Create the Terraform state bucket and DynamoDB lock table (one-time, per AWS account):
   ```
   aws s3api create-bucket --bucket sample-backend-tf-state --region ap-southeast-1 \
     --create-bucket-configuration LocationConstraint=ap-southeast-1
   aws s3api put-bucket-versioning --bucket sample-backend-tf-state \
     --versioning-configuration Status=Enabled
   aws dynamodb create-table --table-name sample-backend-tf-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST --region ap-southeast-1
   ```
2. Create the GitHub OIDC identity provider in IAM (one-time, per AWS account) — `token.actions.githubusercontent.com`, audience `sts.amazonaws.com`.
3. Create an IAM role for GitHub Actions to assume (`staging-sample-backend-oidc`), trusting that OIDC provider, scoped to `repo:Kachenas/template-gen-be:*` (tighten to `ref:refs/heads/staging` once the branch exists). Attach the managed policies listed in the "Required IAM Permission Policies" section printed by the skill, **plus** the DynamoDB state-lock inline policy below — the managed-policy list doesn't cover it.
4. Create the `staging` GitHub environment in the `Kachenas/template-gen-be` repo, and populate its variables/secrets (see the "Suggested GitHub Environment Values" table printed by the skill).
5. Run `terraform init` + `terraform plan` + `terraform apply` from `sample-backend-infrastructure/terraform/environments/staging` locally, with admin AWS credentials — CI's role doesn't exist as something to assume until this first apply creates it... actually the role is created manually in step 3, so CI can run immediately after that. Running the first apply from CI once the role and environment exist is fine too.

## Why did `terraform plan`/`apply` fail on the `aws_route53_record.api_alias` or `data.aws_acm_certificate.wildcard` resources?

The deploy role needs Route53 write access (to create the `staging-api.vibecheckkits.com` alias record) and ACM read access (to look up the existing `*.vibecheckkits.com` regional certificate). Neither is in the managed-policy list from the skill. Attach `AmazonRoute53FullAccess`, plus this inline policy for ACM (read-only — Terraform only looks the cert up, it never creates or modifies one here):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AcmReadOnly",
      "Effect": "Allow",
      "Action": [
        "acm:ListCertificates",
        "acm:DescribeCertificate"
      ],
      "Resource": "*"
    }
  ]
}
```

## Why did `terraform plan`/`apply` fail with `AccessDeniedException ... dynamodb:PutItem/GetItem`?

None of the managed policies above grant DynamoDB access — the S3 backend's state locking needs its own scoped permission on the lock table. Attach this as an inline policy on the deploy role (`template-gen-be/GitHubActions`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateLock",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:ap-southeast-1:183614028822:table/sample-backend-tf-lock"
    }
  ]
}
```

## Why did `terraform apply` fail with `UnauthorizedOperation: ... ec2:TerminateInstances`?

The deploy role is missing `AmazonEC2FullAccess`, which is required because the bastion module manages an EC2 instance. `AmazonVPCFullAccess` covers networking but not plain instance lifecycle actions.

## Why did `terraform apply` fail on `aws_wafv2_web_acl` or `aws_wafv2_web_acl_association`?

The deploy role is missing WAF permissions — attach the managed policy `AWSWAFFullAccess` (covers `wafv2:*`, used to create the rate-based Web ACL and associate it with the ALB).

## Why is the ECS service stuck, tasks cycling?

Almost always the ALB health check failing. Check:
- The task can actually reach `/up` on port 80 inside the container (Laravel 11+ ships this route by default via `bootstrap/app.php`'s `health: '/up'`).
- Secrets Manager values aren't still `CHANGE_ME` placeholders — a bad `APP_KEY` or DB credential will crash the app on boot.
- CloudWatch Logs (`/ecs/staging-sample-backend`) for the actual PHP/nginx error.

## Why did `AssumeRoleWithWebIdentity` fail with `Not authorized`?

The trust policy's `sub` condition doesn't match what GitHub actually sent. Every workflow job that assumes the role has a "Debug OIDC claims" step immediately before "Configure AWS credentials" — check its output for the actual `sub`/`repository` claims rather than guessing.

## How do I add production later?

Copy `sample-backend-infrastructure/terraform/environments/staging` to `environments/production`, change the `local.project_name` prefix to `prod-`, bump `task_cpu`/`task_memory`/`desired_count`/`log_retention_days`/`container_insights` per the skill's production sizing convention, and add `.github/workflows/terraform-production.yml` / `deploy-production.yml` (the production terraform workflow additionally needs the `guard`/`confirm_destroy` job — see the skill's `github-workflows.md` reference).
