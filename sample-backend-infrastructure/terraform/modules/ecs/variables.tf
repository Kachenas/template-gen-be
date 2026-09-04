variable "project_name" { type = string }
variable "aws_region" { type = string }
variable "ecr_repository_url" { type = string }
variable "execution_role_arn" { type = string }
variable "task_role_arn" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_security_group_id" { type = string }
variable "target_group_arn" { type = string }
variable "secrets_arn" { type = string }

variable "task_cpu" {
  type    = number
  default = 256
}
variable "task_memory" {
  type    = number
  default = 512
}
variable "desired_count" {
  type    = number
  default = 1
}
variable "log_retention_days" {
  type    = number
  default = 14
}
variable "container_insights" {
  type    = bool
  default = false
}

variable "container_port" {
  description = "Port the application listens on (from the framework profile)"
  type        = number
  default     = 80
}
variable "container_environment" {
  description = "List of {name, value} plain env vars"
  type        = list(object({ name = string, value = string }))
}
variable "secret_keys" {
  description = "List of Secrets Manager keys to inject as ECS secrets"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
