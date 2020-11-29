module "vpc-endpoints_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "vpc-endpoints_sg"
  description = "Security group with HTTPS ports open for private subnet (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["10.0.0.0/16"]
  ingress_rules       = ["https-443-tcp"]
  tags = {
    Name        = "ptodo"
    Environment = "prod"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ptodo-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.203.0/24"]

  create_database_subnet_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = false

  enable_nat_gateway = false
  enable_vpn_gateway = false

  # VPC endpoint for S3
  enable_s3_endpoint = true

  # VPC endpoint for SSM
  enable_ssm_endpoint              = true
  ssm_endpoint_private_dns_enabled = true
  ssm_endpoint_security_group_ids  = [module.vpc-endpoints_sg.this_security_group_id]

  # VPC endpoint for logs
  enable_logs_endpoint              = true
  logs_endpoint_private_dns_enabled = true
  logs_endpoint_security_group_ids  = [module.vpc-endpoints_sg.this_security_group_id]

  # VPC Endpoint for ECR DKR
  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [module.vpc-endpoints_sg.this_security_group_id]

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
