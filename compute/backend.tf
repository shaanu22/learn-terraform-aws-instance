terraform {
  backend "s3" {
    bucket         = "s3-backend-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}

data "terraform_remote_state" "vpc_id" {
  backend = "s3"

  config = {
    bucket         = "s3-backend-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}

data "terraform_remote_state" "subnet_id" {
  backend = "s3"
  
  config = {
    bucket         = "s3-backend-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}
