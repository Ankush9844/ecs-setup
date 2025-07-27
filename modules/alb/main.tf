#################################################################
# Create Application Load Balancer                              #
#################################################################

resource "aws_lb" "applicationLoadBalancer" {
  name               = "${var.ProjectName}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.appLoadBalancerSecurityGroupID]
  subnets            = concat(var.PublicSubnetIDs)

}

################################################################
# Create Target Group For Frontend                             #
################################################################

resource "aws_lb_target_group" "fargateTargetGroupFrontend" {
  name            = "FargateTargetGroupFrontend"
  target_type     = "ip" # "instance", "lambda"
  port            = 3000 # container port
  protocol        = "HTTP"
  ip_address_type = "ipv4"
  vpc_id          = var.vpcID
  health_check {
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

################################################################
# Create Http Listener For Frontend                            #
################################################################

resource "aws_lb_listener" "fargateHttpListener" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect" #forward
    # target_group_arn = aws_lb_target_group.fargateTargetGroup.arn

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

################################################################
# Create Https Listener For Frontend and Backend               #
################################################################

resource "aws_lb_listener" "fargateHttpsListener" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # Default certificate
  certificate_arn = var.defaultSSLCertificateARN


  default_action {
    type = "fixed-response"   # 
    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }

}


################################################################
# Create Target Goup For Backend                               #
################################################################

resource "aws_lb_target_group" "fargateTargetGroupBackend" {
  name            = "FargateTargetGroupBackend"
  target_type     = "ip" # "instance", "lambda"
  port            = 5000 # container port
  protocol        = "HTTP"
  ip_address_type = "ipv4"
  vpc_id          = var.vpcID
  health_check {
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

################################################################
# Create Listener Rules for Frontend and Backend               #
################################################################

resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.fargateHttpsListener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargateTargetGroupFrontend.arn
  }

  condition {
    host_header {
      values = [var.frontendDomain]
    }
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.fargateHttpsListener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargateTargetGroupBackend.arn
  }

  condition {
    host_header {
      values = [var.backendDomain]
    }
  }
}


################################################################
# Create ALB for EC2 Launch Type                               #
################################################################

# resource "aws_lb_target_group" "ec2TargetGroup" {
#   name            = "${var.ProjectName}-EC2-Target-Group"
#   target_type     = "instance" # "ip", "lambda"
#   port            = 3000       # container port
#   protocol        = "HTTP"
#   ip_address_type = "ipv4"
#   vpc_id          = var.vpcID
#   health_check {
#     protocol            = "HTTP"
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 5
#     unhealthy_threshold = 2
#     matcher             = "200-302"
#   }
# }

# resource "aws_lb_listener" "ec2Listener" {
#   load_balancer_arn = aws_lb.applicationLoadBalancer.arn
#   port              = 80
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ec2TargetGroup.arn
#   }
# }
