variable "project_name" {
  type    = string
  default = "sample-backend"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "health_check_path" {
  type    = string
  default = "/up"
}

variable "db_name" {
  type    = string
  default = "sample"
}

variable "db_username" {
  type    = string
  default = "sample_admin"
}

variable "db_password" {
  description = "RDS master password. Supplied via TF_VAR_db_password in CI — never commit a real value."
  type        = string
  sensitive   = true
}

variable "developer_user_names" {
  description = "IAM user names to grant SSM bastion access for DB tunneling"
  type        = list(string)
  default     = []
}

variable "telescope_enabled" {
  description = "Whether Laravel Telescope records/serves the /telescope dashboard in this environment. Toggling this alone doesn't affect the live ECS service (its task_definition is Terraform-ignored so app deploys aren't clobbered) — see docs/AWS-FAQ.md for how to actually roll the change out."
  type        = bool
  default     = true
}
