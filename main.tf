# -----------------------------------------------------------------------------
# Data sources to get VPC and default security group details
# -----------------------------------------------------------------------------
data "aws_vpc" "prod" {
  tags = {
    Environment = "prod"
  }
}

data "aws_subnet_ids" "public_prod" {
  vpc_id = data.aws_vpc.prod.id
  tags = {
    Environment = "prod"
  }

  filter {
    name   = "mapPublicIpOnLaunch"
    values = ["true"]
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


  subnets = data.aws_subnet_ids.public_prod.ids

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.this_security_group_id,
  ]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ptodo.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Sorry, maintenance now!"
      status_code  = "503"
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
  vpc_id      = data.aws_vpc.prod.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
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
