resource "aws_s3_bucket" "b" {
  bucket = "terraform-shaanu-s3-backend-bucket"
  force_destroy = true
  versioning {
            enabled = true
        }
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "shaanu-example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "shaanu-example-ownership" {
  bucket = aws_s3_bucket.b.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_acl.shaanu-example]
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name     = "terraform-shaanu-s3-backend-table"
  hash_key = "LockID"

  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "dev"
  }
}
