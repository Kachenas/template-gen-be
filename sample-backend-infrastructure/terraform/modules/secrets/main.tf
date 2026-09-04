resource "aws_secretsmanager_secret" "this" {
  name        = var.secret_name
  description = "Application secrets for ${var.secret_name}"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  # Seed with placeholder JSON — real values are populated manually after
  # the first terraform apply.
  secret_string = jsonencode(var.secret_placeholders)

  lifecycle {
    ignore_changes = [secret_string]
  }
}
