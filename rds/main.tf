######################################
# Data sources to get VPC and subnets
######################################
data "aws_region" "current" {}

data "aws_vpc" "ptodo" {
  tags = {
    Name        = "ptodo-vpc"
    Environment = "prod"
  }
}

data "aws_subnet_ids" "db" {
  vpc_id = data.aws_vpc.ptodo.id
  tags = {
    Name        = "ptodo-vpc-db-${data.aws_region.current.name}?"
    Environment = "prod"
  }
}

#############
# RDS Aurora
#############
module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 2.0"

  name                  = "ptodo-rds"
  engine                = "aurora-postgresql"
  engine_mode           = "serverless"
  engine_version        = "10.12"
  replica_scale_enabled = false
  replica_count         = 0

  backtrack_window = 10 # ignored in serverless

  backup_retention_period = 1

  subnets                         = data.aws_subnet_ids.db.ids
  vpc_id                          = data.aws_vpc.ptodo.id
  monitoring_interval             = 60
  apply_immediately               = true
  skip_final_snapshot             = true
  storage_encrypted               = true
  db_parameter_group_name         = aws_db_parameter_group.ptodo_aurora-postgresql10_db_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.ptodo_aurora-postgresql10_cluster_parameter_group.id

  #  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"] # Aurora Serverless currently doesn't support CloudWatch Log Export.

  # See: https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/AuroraUserGuide/data-api.html#data-api.enabling
  enable_http_endpoint = true

  scaling_configuration = {
    auto_pause               = true
    max_capacity             = 4
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
}

resource "aws_db_parameter_group" "ptodo_aurora-postgresql10_db_parameter_group" {
  name        = "ptodo-aurora-postgresql10-parameter-group"
  family      = "aurora-postgresql10"
  description = "ptodo-aurora-postgresql10-parameter-group"

  # See: https://aws.amazon.com/jp/premiumsupport/knowledge-center/rds-postgresql-query-logging/
  parameter {
    name  = "log_statement"
    value = "all"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}

resource "aws_rds_cluster_parameter_group" "ptodo_aurora-postgresql10_cluster_parameter_group" {
  name        = "ptodo-aurora-postgresql10-cluster-parameter-group"
  family      = "aurora-postgresql10"
  description = "ptodo-aurora-postgresql10-cluster-parameter-group"
}


############################
# Example of security group
############################
resource "aws_security_group" "app_servers" {
  name        = "app-servers"
  description = "For application servers"
  vpc_id      = data.aws_vpc.ptodo.id
}

resource "aws_security_group_rule" "allow_access" {
  type                     = "ingress"
  from_port                = module.aurora.this_rds_cluster_port
  to_port                  = module.aurora.this_rds_cluster_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = module.aurora.this_security_group_id
}
