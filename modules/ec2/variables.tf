variable "my_ip_address" {}

variable "instance_type" {}

variable "instance_id" {}

variable "vpc_id" {}

variable "domain_name" {
  description = "domain name"
  type        = string
}

variable "record_name" {
  description = "sub domain name"
  type        = string
}
