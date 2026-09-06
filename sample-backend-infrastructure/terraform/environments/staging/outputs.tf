output "alb_dns_name" { value = module.alb.alb_dns_name }
output "ecr_repository_url" { value = module.ecr.repository_url }
output "ecs_cluster_name" { value = module.ecs.cluster_name }
output "ecs_service_name" { value = module.ecs.service_name }
output "db_endpoint" { value = module.rds.db_endpoint }
output "db_host" { value = module.rds.db_host }
output "db_port" { value = module.rds.db_port }
output "bastion_instance_id" { value = module.bastion.instance_id }
output "app_url" { value = var.custom_domain != "" ? "https://${var.custom_domain}" : "http://${module.alb.alb_dns_name}" }
