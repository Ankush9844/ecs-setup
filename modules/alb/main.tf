resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = concat(var.public_subnet_ids)

}

# resource "aws_lb_target_group" "alb_target_group" {
#   name            = "alb-tg"
#   target_type     = "ip" # "instance", "lambda"
#   port            = 3000 # container port
#   protocol        = "HTTP"
#   ip_address_type = "ipv4"
#   vpc_id          = var.vpc_id
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

# resource "aws_lb_listener" "alb_listener" {
#   load_balancer_arn = aws_lb.app_alb.arn
#   port              = 80
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.alb_target_group.arn
#   }
# }



#####################################

resource "aws_lb_target_group" "alb_target_group_2" {
  name            = "${var.project_name}-EC2-tg"
  target_type     = "instance" # "ip", "lambda"
  port            = 3000 # container port
  protocol        = "HTTP"
  ip_address_type = "ipv4"
  vpc_id          = var.vpc_id
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

resource "aws_lb_listener" "alb_listener_2" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_2.arn
  }
}