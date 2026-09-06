variable "project_name" { type = string }
variable "alb_arn" { type = string }

variable "rate_limit" {
  description = "Max requests from a single IP within a rolling 5-minute window before WAF blocks it. AWS enforces a minimum of 100."
  type        = number
  default     = 2000
}

variable "tags" {
  type    = map(string)
  default = {}
}
