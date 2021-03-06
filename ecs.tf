# -----------------------------------------------------------------------------
# Data sources to get aws_region and rds cluster
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_rds_cluster" "ptodo" {
  cluster_identifier = "ptodo-rds"
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

resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  container_definitions    = <<EOF
  [
    {
      "name": "frontend",
      "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ptodo/frontend:latest",
      "environment": [
        {"name": "VITE_API_ENDPOINT","value": "https://${aws_route53_record.ptodo.name}/todos/"}
      ],
      "command": [],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-stream-prefix": "frontend",
          "awslogs-group": "/ecs/ptodo"
        }
      },
      "portMappings": [
        {
          "protocol":"tcp",
          "containerPort":8080
        }
      ]
    }
  ]
  EOF
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "backend"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  container_definitions    = <<EOF
  [
    {
      "name": "backend",
      "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ptodo/backend:latest",
      "cpu": 0,
      "environment": [
        {"name": "DATABASE","value": "postgresql"},
        {"name": "DB_HOST","value": "${data.aws_rds_cluster.ptodo.endpoint}"},
        {"name": "DB_NAME", "value": "ptodo"},
        {"name": "DB_PORT", "value": "5432"}
      ],
      "secrets": [
        {"name": "DB_USERNAME", "valueFrom": "/db/username"},
        {"name": "DB_PASSWORD", "valueFrom": "/db/password"}
      ],
      "command": ["uvicorn", "app.main:app", "--workers", "1", "--reload", "--host", "0.0.0.0", "--port", "8000"],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-stream-prefix": "backend",
          "awslogs-group": "/ecs/ptodo"
        }
      },
      "mountPoints": [],
      "volumesFrom": [],
      "portMappings": [
        {
          "protocol":"tcp",
          "containerPort":8000,
          "hostPort": 8000
        }
      ]
    }
  ]
  EOF
}

resource "aws_ecs_service" "frontend" {
  name                              = "frontend"
  cluster                           = aws_ecs_cluster.ptodo.arn
  task_definition                   = aws_ecs_task_definition.frontend.arn
  desired_count                     = 3
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = true
    security_groups = [
      module.frontend_sg.this_security_group_id,
      "sg-00a0759bb8fb650b3"
    ]

    subnets = data.aws_subnet_ids.public.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ptodo.arn
    container_name   = "frontend"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "backend" {
  name             = "backend"
  cluster          = aws_ecs_cluster.ptodo.arn
  task_definition  = aws_ecs_task_definition.backend.arn
  desired_count    = 3
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    assign_public_ip = true
    security_groups = [
      module.backend_sg.this_security_group_id,
      "sg-0720af5f93ca52a6b"
    ]

    subnets = data.aws_subnet_ids.public.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "backend"
    container_port   = 8000
  }

  lifecycle {
    ignore_changes = [desired_count]
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
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "frontend service ports"
      cidr_blocks = data.aws_vpc.ptodo.cidr_block
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]


  tags = {
    Name        = "ptodo"
    Service     = "frontend"
    Environment = "prod"
  }
}

module "backend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "backend_sg"
  description = "Security group with HTTP:8000 ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.ptodo.id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8000
      to_port                  = 8000
      protocol                 = "tcp"
      description              = "backend service ports"
      source_security_group_id = "sg-00a0759bb8fb650b3"
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name        = "ptodo"
    Service     = "backend"
    Environment = "prod"
  }
}
