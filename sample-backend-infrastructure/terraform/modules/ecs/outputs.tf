output "cluster_name" { value = aws_ecs_cluster.this.name }
output "service_name" { value = aws_ecs_service.this.name }
output "task_definition_family" { value = aws_ecs_task_definition.this.family }
output "container_name" { value = var.project_name }
