# locals {
#   target_subnets = "${var.internal == true ? data.aws_subnet_ids.private.ids : data.aws_subnet_ids.public.ids}"
# }

resource "aws_lb" "main" {
  name               = format("%s-%s", var.environment, var.name)
  load_balancer_type = "network"

  # launch lbs in public or private subnets based on "internal" variable
  internal = var.internal
  subnets  = var.lb_subnets


  tags = "${merge(
    var.tags,
    map("Name", format("%s-%s-nlb", var.environment, var.name)),
  )}"
}

# adds a tcp listener to the load balancer and allows ingress
resource "aws_lb_listener" "app_port" {
  load_balancer_arn = aws_lb.main.id
  port              = var.port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "main" {
  name                 = format("%s-%s", var.environment, var.name)
  port                 = var.port
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    protocol            = "TCP"
    port                = var.port
    interval            = var.health_check_interval
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = "${merge(
    var.tags,
    map("Name", format("%s-%s-tg", var.environment, var.name)),
  )}"
}
