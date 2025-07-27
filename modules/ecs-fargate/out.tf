output "ecsClusterName" {
  value = aws_ecs_cluster.main.name
}
output "ecsFrontendServiceName" {
  value = aws_ecs_service.fargateServiceFrontend.name
}
output "ecsBackendServiceName" {
  value = aws_ecs_service.fargateServiceBackend.name
}