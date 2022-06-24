terraform {
  backend "s3" {
    bucket         = "s3-backend-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}

/*data "aws_availability_zones" "available" {
  state = "available"
}*/

data "terraform_remote_state" "vpc_id" {
  backend = "s3"

  config = {
    bucket         = "s3-backend-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}



/*data "aws_availability_zones" "elb-ec2-az" {
  all_availability_zones = true

  filter {
    name   = "opt-in-status"
    values = ["not-opted-in", "opted-in"]
  }
}*/




/*data "terraform_remote_state" "aws_subnet" {
  backend = "local"

  config = {
    path = "../network-config/main.tf"
  }
}*/

/*data "terraform_remote_state" "cidr_block" {
  backend = "s3"

  config = {
    bucket         = "s3-backend-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}*/

/*locals {
  vpcId = data.terraform_remote_state.vpc_id.outputs.vpc_id
}*/
