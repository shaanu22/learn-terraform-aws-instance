module "ec2" {
  source = "../modules/ec2"

  instance_type = var.instance_type
  instance_id   = var.instance_id
  my_ip_address = var.my_ip_address
  vpc_id        = module.vpc.vpc_id


  #roles         = var.roles
  #my_vpc_cidr  = module.vpc.cidr_vpc
  #s3fullaccess = var.s3fullaccess
}

/*module "vpc" {
  source = "../modules/vpc"
  my_vpc_cidr        = var.my_vpc_cidr
  public_cidr        = var.public_cidr
  private_cidr       = var.private_cidr
  availability_zones = var.availability_zones
}*/