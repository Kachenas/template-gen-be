variable "project_name" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "engine_version" {
  type    = string
  default = "16"
}

variable "db_name" { type = string }
variable "db_username" { type = string }

variable "db_password" {
  type      = string
  sensitive = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 0
}

variable "tags" {
  type    = map(string)
  default = {}
}
