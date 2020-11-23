module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ptodo-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.203.0/24"]

  create_database_subnet_group = false

  map_public_ip_on_launch = false

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
