variable "project_name" { type = string }
variable "bastion_instance_arn" { type = string }
variable "developer_user_names" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
