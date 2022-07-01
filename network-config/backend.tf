terraform {
  backend "s3" {
    bucket         = "s3-backend-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}
