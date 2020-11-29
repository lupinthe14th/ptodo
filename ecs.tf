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
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "ecs_task_execution_role" {
  source     = "./modules/iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

resource "aws_ecs_cluster" "ptodo" {
  name = "ptodo"
}

resource "aws_ecs_task_definition" "ptodo" {
  family                   = "ptodo"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  container_definitions    = file("./container_definitions.json")
}

resource "aws_ecs_service" "ptodo" {
  name                              = "ptodo"
  cluster                           = aws_ecs_cluster.ptodo.arn
  task_definition                   = aws_ecs_task_definition.ptodo.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.frontend_sg.this_security_group_id]

    subnets = data.aws_subnet_ids.private.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ptodo.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
data "aws_region" "current" {}

data "aws_vpc_endpoint" "s3" {
  vpc_id       = data.aws_vpc.ptodo.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

module "frontend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "frontend_sg"
  description = "Security group with HTTP:3000 ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.ptodo.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "frontend service ports"
      cidr_blocks = data.aws_vpc.ptodo.cidr_block
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name        = "ptodo"
    Environment = "prod"
  }
}
