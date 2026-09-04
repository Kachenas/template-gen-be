variable "secret_name" { type = string }
variable "secret_placeholders" {
  description = "Map of secret keys to CHANGE_ME placeholder values (APP_KEY plus DB_* for this project)"
  type        = map(string)
}
variable "tags" {
  type    = map(string)
  default = {}
}
