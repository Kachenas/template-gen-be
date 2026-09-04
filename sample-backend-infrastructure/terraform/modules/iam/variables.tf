variable "project_name" { type = string }
variable "ecr_repository_arn" { type = string }
variable "secrets_arn" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
