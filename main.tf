provider "aws" {
  region = "us-east-1"
}

module "instance_group" {
  source         = "./modules/ec2"
  my_ip_address  = var.my_ip_address
  instance-type  = var.instance-type
  instance_id    = var.instance_id
  instance_value = var.instance_value
  aws_iam_role   = var.aws_iam_role
  roles          = var.roles
}

module "main_vpc" {
  source             = "./modules/vpc"
  my_vpc_cidr        = var.my_vpc_cidr
  public_cidr        = var.public_cidr
  private_cidr       = var.private_cidr
  availability_zones = var.availability_zones
}
