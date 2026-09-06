# Rate-based IP blocking for the ALB: any single IP exceeding var.rate_limit
# requests within a rolling 5-minute window is automatically blocked by WAF
# for as long as its rate stays over that threshold, then unblocked once it
# drops back down. This is AWS's actual DDoS/abuse auto-ban mechanism —
# Shield Standard (already active on every ALB at no extra cost) covers
# network/transport-layer (L3/L4) attacks, this rule covers the
# application-layer (L7) request-flood case Shield Standard doesn't.
resource "aws_wafv2_web_acl" "this" {
  name        = "${var.project_name}-waf"
  description = "Rate-based abuse/DDoS protection for ${var.project_name}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit-per-ip"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
