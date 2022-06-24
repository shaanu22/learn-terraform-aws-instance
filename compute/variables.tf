variable "my_ip_address" {}

variable "public_key_location" {}

variable "instance-type" {}

variable "private_cidr" {
  type = list(any)
}

variable "my_vpc_cidr" {}

variable "vpc_id" {}

variable "subnet_id" {}

#variable "aws_internet_gateway" {}

#variable "public_key_location" {} 

#variable "my_ip_address" {}



#variable "asg" {}
