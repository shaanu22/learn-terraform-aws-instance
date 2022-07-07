terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "s3-backend-bucket"
    key            = "network-config.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}

provider "aws" {
  region = "us-east-1"
}
