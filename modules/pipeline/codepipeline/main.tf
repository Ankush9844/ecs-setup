################################################################
# Create IAM Role for Codepipeline                             #
################################################################

resource "aws_iam_role" "codepipelineRole" {
  name = "CodepipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipelineRole.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codepipelineRole.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role_policy" "codepipelineCustomPolicy" {
  name = "codepipelineCustom"
  role = aws_iam_role.codepipelineRole.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:GetConnectionToken",
          "codestar-connections:GetConnection",
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection",
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ],
        Resource = [
          "arn:aws:codestar-connections:${var.aws_region}:${var.account_id}:connection/${local.connection_id}",
          "${data.aws_codestarconnections_connection.github.arn}"
        ]
      },
      {
        "Sid" : "TaskDefinitionPermissions",
        "Effect" : "Allow",
        "Action" : [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Sid" : "ECSServicePermissions",
        "Effect" : "Allow",
        "Action" : [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ],
        "Resource" : [
          "arn:aws:ecs:*:600748199510:service/*"
        ]
      },
      {
        "Sid" : "ECSTagResource",
        "Effect" : "Allow",
        "Action" : [
          "ecs:TagResource"
        ],
        "Resource" : [
          "arn:aws:ecs:*:600748199510:task-definition/arn:aws:ecs:us-east-1:600748199510:task-definition/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "ecs:CreateAction" : [
              "RegisterTaskDefinition"
            ]
          }
        }
      },
      {
        "Sid" : "IamPassRolePermissions",
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : [
          "arn:aws:iam::600748199510:role/ecsTaskExecutionRole"
        ],
        "Condition" : {
          "StringEquals" : {
            "iam:PassedToService" : [
              "ecs.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

################################################################
# Get Github Connection                                        #
################################################################

data "aws_codestarconnections_connection" "github" {
  name = var.githubConnection
}
locals {
  connection_id = split("/", data.aws_codestarconnections_connection.github.arn)[1]
}

################################################################
# Create S3 Bucket for Pipeline                                #
################################################################

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline-artifacts-bucket-3924"
}

################################################################
# Create Pipeline for Frontend                                 #
################################################################

resource "aws_codepipeline" "chatappFrontendpipeline" {
  name     = "chatapp-frontend"
  role_arn = aws_iam_role.codepipelineRole.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_bucket.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github.arn
        FullRepositoryId = "Ankush9844/auth_app"
        BranchName       = "frontend"
        DetectChanges    = "true"
      }

      run_order = 1
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = var.codeBuildFrontendProject
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "ECS_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = var.ecsClusterName
        ServiceName = var.ecsFrontendServiceName
        FileName    = "imagedefinitions.json"
      }
    }
  }
}


################################################################
# Create Pipeline for Backend                                  #
################################################################

resource "aws_codepipeline" "chatappBackendPipeline" {
  name     = "chatapp-backend"
  role_arn = aws_iam_role.codepipelineRole.arn

  artifact_store {
    type     = "S3"
    location = "codepipeline-artifacts-bucket-3924"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github.arn
        FullRepositoryId = "Ankush9844/auth_app"
        BranchName       = "backend"
        DetectChanges    = "true"
      }

      run_order = 1
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = var.codeBuildBackendProject
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "ECS_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = var.ecsClusterName
        ServiceName = var.ecsBackendServiceName
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
