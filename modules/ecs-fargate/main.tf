resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "${var.ProjectName}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionPolicy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



resource "aws_ecs_cluster" "main" {
  name = var.ProjectName
}

resource "aws_ecs_task_definition" "fargateTaskDefination" {
  family                   = "fargateTaskDefination"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([
    {
      name      = "chatapp"
      image     = var.containerImage
      environment = [
        {
          name = "API_BASE_URL"
          value = "https://backend.anshtechnolabs.shop"
        }
      ]
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      
    }
  ])
}

resource "aws_ecs_service" "fargateService" {
  name            = "fargateService"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fargateTaskDefination.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = concat(var.PublicSubnetIDs)
    security_groups = [var.ecsFargateSecurityGroupID]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.fargateTargetGroupARN
    container_name   = "chatapp"
    container_port   = 3000
  }

  depends_on = [aws_ecs_task_definition.fargateTaskDefination]
}





resource "aws_ecs_task_definition" "fargateTaskDefinationBackend" {
  family                   = "fargateTaskDefinationBackend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([
    {
      name      = "chatapp-backend"
      image     = var.containerImageBackend
      environment = [
        {
          name = "DB_HOST"
          value = "mydatabase.c4746w0oaaag.us-east-1.rds.amazonaws.com"
        },
        {
          name = "DB_PORT"
          value = "3306"
        },
        {
          name = "DB_USER"
          value = "admin"
        },
        {
          name = "DB_PASSWORD"
          value = "7942c1e863f52540"
        },
        {
          name = "DATABASE"
          value = "auth_app"
        },
        {
          name = "JWT_SECRET_KEY"
          value = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJPbmxpbmUgSldUIEJ1YiI6IkpvaG5ueSIsIlN1cm5hbWUiOiJSb2NrZXQiLCJFbWFpbCI6Impyb2NrZXRAZXhhbXBsZS5jb20iLCJSb2xlIjpbIk1hbmFnZXIiLCJQcm9qZWN0IEFkbWluaXN0cmF0b3IiXX0.RSq0eQtMWrxk4xxSiF8kD9B1L_8WExdEy-pCzrwSuYY"
        }
      ]
      essential = true
      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "fargateServiceBackend" {
  name            = "fargateServiceBackend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fargateTaskDefinationBackend.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = concat(var.PublicSubnetIDs)
    security_groups = [var.ecsFargateSecurityGroupBackendID]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.fargateTargetGroupBackendARN
    container_name   = "chatapp-backend"
    container_port   = 5000
  }

  depends_on = [aws_ecs_task_definition.fargateTaskDefinationBackend]
}