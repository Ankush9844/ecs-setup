output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ecs_task_sg_id" {
  value = aws_security_group.ecs_tasks.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_sg.id
}