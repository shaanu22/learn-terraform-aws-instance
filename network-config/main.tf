module vpc {
  source = "../modules/vpc"

  my_vpc_cidr        = var.my_vpc_cidr
  public_cidr        = var.public_cidr
  private_cidr       = var.private_cidr
  availability_zones = var.availability_zones
}
