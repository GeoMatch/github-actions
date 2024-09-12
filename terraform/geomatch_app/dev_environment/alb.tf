resource "aws_lb_target_group" "this" {
  name        = "${var.project}-${var.name}" # Only 32 chars
  port        = local.container_port_num
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.networking_module.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "20"
    path                = var.health_check_path
    unhealthy_threshold = "3"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_acm_certificate" "this" {
  domain      = var.acm_cert_domain
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = var.alb_module.alb_arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.this.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # TODO(P2): Consider listener rules to suppliment Stanford-VPN limited security group rule
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = var.alb_module.alb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
