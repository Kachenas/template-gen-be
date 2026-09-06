terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Bucket/key/region/dynamodb_table are supplied via -backend-config in CI
    # (see .github/workflows/terraform-production.yml) or a local backend-config
    # file when running Terraform by hand. Never hardcode them here.
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project_name = "prod-${var.project_name}"

  tags = {
    Project     = var.project_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

module "networking" {
  source = "../../modules/networking"

  project_name = local.project_name
  vpc_cidr     = "10.1.0.0/16"
  tags         = local.tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = local.project_name
  tags            = local.tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  project_name   = local.project_name
  vpc_id         = module.networking.vpc_id
  container_port = var.container_port
  tags           = local.tags
}

module "secrets" {
  source = "../../modules/secrets"

  secret_name = local.project_name

  secret_placeholders = {
    APP_KEY     = "CHANGE_ME"
    DB_HOST     = "CHANGE_ME"
    DB_PORT     = "CHANGE_ME"
    DB_DATABASE = "CHANGE_ME"
    DB_USERNAME = "CHANGE_ME"
    DB_PASSWORD = "CHANGE_ME"
  }

  tags = local.tags
}

module "iam" {
  source = "../../modules/iam"

  project_name       = local.project_name
  ecr_repository_arn = module.ecr.repository_arn
  secrets_arn        = module.secrets.secret_arn
  tags               = local.tags
}

module "alb" {
  source = "../../modules/alb"

  project_name      = local.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id
  container_port    = var.container_port
  health_check_path = var.health_check_path
  certificate_arn   = local.certificate_arn
  tags              = local.tags
}

module "waf" {
  source = "../../modules/waf"

  project_name = local.project_name
  alb_arn      = module.alb.alb_arn
  tags         = local.tags
}

module "rds" {
  source = "../../modules/rds"

  project_name            = local.project_name
  private_subnet_ids      = module.networking.private_subnet_ids
  security_group_id       = module.security_groups.rds_security_group_id
  instance_class          = "db.t3.small"
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  skip_final_snapshot     = false
  backup_retention_period = 7
  tags                    = local.tags
}

module "bastion" {
  source = "../../modules/bastion"

  project_name      = local.project_name
  subnet_id         = module.networking.private_subnet_ids[0]
  security_group_id = module.security_groups.bastion_security_group_id
  tags              = local.tags
}

module "iam_developers" {
  source = "../../modules/iam-developers"

  project_name         = local.project_name
  bastion_instance_arn = module.bastion.instance_arn
  developer_user_names = var.developer_user_names
  tags                 = local.tags
}

module "ecs" {
  source = "../../modules/ecs"

  project_name          = local.project_name
  aws_region            = var.aws_region
  ecr_repository_url    = module.ecr.repository_url
  execution_role_arn    = module.iam.ecs_task_execution_role_arn
  task_role_arn         = module.iam.ecs_task_role_arn
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.security_groups.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn
  secrets_arn           = module.secrets.secret_arn
  container_port        = var.container_port
  task_cpu              = 512
  task_memory           = 1024
  desired_count         = 2
  log_retention_days    = 90
  container_insights    = true

  container_environment = [
    { name = "APP_ENV", value = "production" },
    { name = "APP_DEBUG", value = "false" },
    { name = "APP_URL", value = var.custom_domain != "" ? "https://${var.custom_domain}" : "http://${module.alb.alb_dns_name}" },
    { name = "LOG_CHANNEL", value = "stderr" },
    { name = "DB_CONNECTION", value = "pgsql" },
    { name = "DB_SSLMODE", value = "require" },
    { name = "RUN_MIGRATIONS", value = "true" },
    { name = "TELESCOPE_ENABLED", value = var.telescope_enabled ? "true" : "false" },
    { name = "CORS_ALLOWED_ORIGINS", value = "https://portal.vibecheckkits.com" },
  ]

  secret_keys = [
    "APP_KEY",
    "DB_HOST",
    "DB_PORT",
    "DB_DATABASE",
    "DB_USERNAME",
    "DB_PASSWORD",
  ]

  tags = local.tags
}
