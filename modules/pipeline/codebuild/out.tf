output "connection_id" {
  value = local.connection_id
}


output "codeconnect_arn" {
  value = data.aws_codestarconnections_connection.github.arn
}

output "codeBuildFrontendProject" {
  value = aws_codebuild_project.codeBuildFrontendProject.name
}

output "codeBuildBackendProject" {
  value = aws_codebuild_project.codeBuildBackendProject.name
}