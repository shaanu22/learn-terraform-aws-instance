resource "aws_s3_bucket_acl" "remote-state" {
  bucket = aws_s3_bucket.s3-backend-bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "remote-state-ownership" {
  bucket = aws_s3_bucket.s3-backend-bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_acl.remote-state]
}

resource "aws_dynamodb_table" "lock" {
  name     = "lock"
  hash_key = "LockID"

  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "lock"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "s3-backend-bucket" {
  bucket        = "s3-backend-bucket"
  force_destroy = true
  versioning {
    enabled = true
  }
  tags = {
    Name = "s3-backend-bucket"
  }
}
