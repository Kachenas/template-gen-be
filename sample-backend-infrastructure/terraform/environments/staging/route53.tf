# Custom domain support: reuses the existing Route53 hosted zone and the
# existing regional (ap-southeast-1) ACM wildcard certificate for
# var.root_domain — both already exist and are managed outside this stack,
# so this file only looks them up and points a record at the ALB.

data "aws_route53_zone" "root" {
  count = var.custom_domain != "" ? 1 : 0
  name  = var.root_domain
}

data "aws_acm_certificate" "wildcard" {
  count       = var.custom_domain != "" ? 1 : 0
  domain      = "*.${var.root_domain}"
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_route53_record" "api_alias" {
  count   = var.custom_domain != "" ? 1 : 0
  zone_id = data.aws_route53_zone.root[0].zone_id
  name    = var.custom_domain
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

locals {
  certificate_arn = var.custom_domain != "" ? data.aws_acm_certificate.wildcard[0].arn : ""
}
