# -----------------------------------------------------------------------------
# Data sources to get Private subnet
# -----------------------------------------------------------------------------
data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.ptodo.id
  tags = {
    Name        = "ptodo-vpc-private-ap-northeast-1?"
    Environment = "prod"
  }
}

# -----------------------------------------------------------------------------
# ECS
# -----------------------------------------------------------------------------
resource "aws_ecs_cluster" "ptodo" {
  name = "ptodo"
}

resource "aws_ecs_task_definition" "ptodo" {
  family                   = "ptodo"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
}

resource "aws_ecs_service" "ptodo" {
  name                              = "ptodo"
  cluster                           = aws_ecs_cluster.ptodo.arn
  task_definition                   = aws_ecs_task_definition.ptodo.arn
  desired_count                     = 0
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.frontend_sg.this_security_group_id]

    subnets = data.aws_subnet_ids.private.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx.arn
    container_name   = "frontend"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}


# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
module "frontend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "frontend_sg"
  description = "Security group with HTTP:3000 ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.ptodo.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "frontend service ports"
      cidr_blocks = data.aws_vpc.ptodo.cidr_block
    }
  ]

  tags = {
    Name        = "ptodo"
    Environment = "prod"
  }
}
