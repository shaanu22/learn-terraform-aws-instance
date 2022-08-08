module "ec2" {
  source = "../modules/ec2"

  domain_name   = var.domain_name
  record_name   = var.record_name
  instance_type = var.instance_type
  instance_id   = var.instance_id
  my_ip_address = var.my_ip_address
  vpc_id        = data.terraform_remote_state.network-config.outputs.vpc_id
}
