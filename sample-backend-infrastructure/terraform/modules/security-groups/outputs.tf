output "alb_security_group_id" { value = aws_security_group.alb.id }
output "ecs_security_group_id" { value = aws_security_group.ecs.id }
output "rds_security_group_id" { value = aws_security_group.rds.id }
output "bastion_security_group_id" { value = aws_security_group.bastion.id }
