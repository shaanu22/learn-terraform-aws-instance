terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "samuel-s3-backend-bucket"
    key            = "compute.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}

provider "aws" {
  region = "us-east-1"
}
