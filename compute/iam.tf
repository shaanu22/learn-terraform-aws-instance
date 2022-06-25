resource "aws_iam_role" "s3fullaccess_role" {
  name = "Hello-DevOps"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
    }
  )

  inline_policy {
    name = "s3FullAccess"

    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Action   = ["s3:*"]
            Effect   = "Allow"
            Resource = "*"
          },
        ]
      }
    )
  }
}

resource "aws_iam_instance_profile" "s3fullaccess_role" {
  name = "Hello-DevOps"
  role = aws_iam_role.s3fullaccess_role.name
}
