data "terraform_remote_state" "network-config" {
  backend = "s3"

  config = {
    bucket = "s3-backend-bucket"
    key    = "network-config.tfstate"
    region = "us-east-1"
  }
}