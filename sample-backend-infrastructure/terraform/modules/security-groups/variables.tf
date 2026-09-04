variable "project_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "container_port" {
  description = "Port the application listens on inside the container"
  type        = number
  default     = 80
}
variable "tags" {
  type    = map(string)
  default = {}
}
