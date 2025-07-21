resource "aws_lb" "applicationLoadBalancer" {
  name               = "${var.ProjectName}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.appLoadBalancerSecurityGroupID]
  subnets            = concat(var.PublicSubnetIDs)

}

###############################################################
resource "aws_lb_target_group" "fargateTargetGroup" {
  name            = "${var.ProjectName}-FargateTargetGroup"
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
    matcher             = "200-302"
  }
}

resource "aws_lb_listener" "fargateListener" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "redirect"    #forward
    # target_group_arn = aws_lb_target_group.fargateTargetGroup.arn

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}



resource "aws_lb_listener" "httpsListener" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # Default certificate
  certificate_arn = "arn:aws:acm:us-east-1:600748199510:certificate/913013be-9dbb-423a-8292-6e1403192095"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargateTargetGroup.arn
  }
  
}

resource "aws_lb_listener_certificate" "additional_cert" {
  listener_arn    = aws_lb_listener.httpsListener.arn
  certificate_arn = "arn:aws:acm:us-east-1:600748199510:certificate/a16e5217-071a-4244-9bde-25868fd647ee"
}

resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.httpsListener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargateTargetGroup.arn
  }

  condition {
    host_header {
      values = ["frontend.anshtechnolabs.shop"]
    }
  }
}






###############################################################



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
    matcher             = "200-499"
  }
}


resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.httpsListener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargateTargetGroupBackend.arn
  }

  condition {
    host_header {
      values = ["backend.anshtechnolabs.shop"]
    }
  }
}


#####################################

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
