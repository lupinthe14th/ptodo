# -----------------------------------------------------------------------------
# Data sources to get VPC
# -----------------------------------------------------------------------------
data "aws_vpc" "ptodo" {
  tags = {
    Name        = "ptodo-vpc"
    Environment = "prod"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.ptodo.id
  tags = {
    Name        = "ptodo-vpc-public-${data.aws_region.current.name}?"
    Environment = "prod"
  }
}


# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-ptodo"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}
# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------
resource "aws_lb" "ptodo" {
  name                       = "ptodo"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = true


  subnets = data.aws_subnet_ids.public.ids

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.this_security_group_id,
    module.https_sg.this_security_group_id,
  ]
  tags = {
    Name        = "ptodo"
    Environment = "prod"
  }

}

resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.ptodo.arn
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ptodo.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.ptodo.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<html><head><title>Sorry, maintenance now!</title></head><body><center><h1>Sorry, maintenance now!</h1></center></body></html>"
      status_code  = "503"
    }
  }
}

resource "aws_lb_target_group" "ptodo" {
  name                 = "ptodo"
  target_type          = "ip"
  vpc_id               = data.aws_vpc.ptodo.id
  port                 = "3000"
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.ptodo]
}

resource "aws_lb_listener_rule" "ptodo" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ptodo.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_listener_rule" "maintenance" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<html><head><title>Sorry, maintenance now!</title></head><body><center><h1>Sorry, maintenance now!</h1></center></body></html>"
      status_code  = "503"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}


# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
module "http_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "http_sg"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.ptodo.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  tags = {
    Name        = "ptodo"
    Environment = "prod"
  }
}

module "https_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "https_sg"
  description = "Security group with HTTPS ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.ptodo.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]
  tags = {
    Name        = "ptodo"
    Environment = "prod"
  }
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------
data "aws_route53_zone" "ptodo_ordinarius-fectum" {
  name = "ordinarius-fectum.net"
}

resource "aws_route53_record" "ptodo" {
  zone_id = data.aws_route53_zone.ptodo_ordinarius-fectum.zone_id
  name    = "ptodo.${data.aws_route53_zone.ptodo_ordinarius-fectum.name}"
  type    = "A"

  alias {
    name                   = aws_lb.ptodo.dns_name
    zone_id                = aws_lb.ptodo.zone_id
    evaluate_target_health = true
  }
}
# -----------------------------------------------------------------------------
# ACM
# -----------------------------------------------------------------------------
resource "aws_acm_certificate" "ptodo" {
  domain_name               = aws_route53_record.ptodo.name
  subject_alternative_names = []
  validation_method         = "DNS"

  tags = {
    Name        = "ptodo"
    Environment = "prod"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ptodo_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.ptodo.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.ptodo_ordinarius-fectum.zone_id
}

resource "aws_acm_certificate_validation" "ptodo" {
  certificate_arn         = aws_acm_certificate.ptodo.arn
  validation_record_fqdns = [for record in aws_route53_record.ptodo_certificate : record.fqdn]
}
