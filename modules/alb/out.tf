output "fargateTargetGroupFrontendARN" {
  value = aws_lb_target_group.fargateTargetGroupFrontend.arn
}
# output "ec2TargetGroupARN" {
#   value = aws_lb_target_group.ec2TargetGroup.arn
# }

output "fargateTargetGroupBackendARN" {
  value = aws_lb_target_group.fargateTargetGroupBackend.arn
}