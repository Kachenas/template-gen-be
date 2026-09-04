resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.project_name}-db-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  skip_final_snapshot     = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_period

  tags = merge(var.tags, { Name = "${var.project_name}-postgres" })
}
