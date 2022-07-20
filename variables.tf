variable "my_ip_address" {}

variable "instance-type" {}

variable "instance_id" {}

variable "instance_value" {}

variable "my_vpc_cidr" {}

variable "public_cidr" {
  description = "cidr for public subnet"
}

variable "private_cidr" {
  description = "cidr for private subnet"
}

variable "availability_zones" {
  type        = list(any)
  description = "AZ in which all the resources will be deployed"
}

variable "aws_iam_role" {}

variable "roles" {}