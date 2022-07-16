resource "aws_iam_role" "asg-roles" {
  name = "asg-roles"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ec2.amazonaws.com", "ssm.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "asg-roles"
  }
}

resource "aws_iam_policy" "s3fullaccess" {
  name        = "s3fullaccess"
  description = "Policy for s3 full access"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "asg-roles" {
  name = "asg-roles"
  role = aws_iam_role.asg-roles.name
}

resource "aws_iam_role_policy_attachment" "s3fullaccess-policy" {
  role       = aws_iam_role.asg-roles.name
  policy_arn = aws_iam_policy.s3fullaccess.arn
}
