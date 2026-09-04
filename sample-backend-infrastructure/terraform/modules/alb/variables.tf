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
variable "certificate_arn" {
  description = "ACM certificate ARN (regional, same region as the ALB) for the HTTPS listener. Leave blank to serve plain HTTP only."
  type        = string
  default     = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
