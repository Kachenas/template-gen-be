variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "container_port" {
  description = "Port the application listens on (from the framework profile)"
  type        = number
  default     = 80
}
variable "health_check_path" {
  description = "Path the ALB health check requests — /up for Laravel"
  type        = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
