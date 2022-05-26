#backend configuration

terraform {
  backend "s3" {
    bucket = "terraform-shaanu-s3-backend-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-shaanu-s3-backend-table"
  }
}

