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
