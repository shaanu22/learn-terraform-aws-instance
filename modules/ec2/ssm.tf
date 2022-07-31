resource "aws_iam_role" "SSMRole" {
  name = "SSMRole"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Principal": {"Service": "ssm.amazonaws.com"},
      "Action": "sts:AssumeRole"
   }
 }
EOF
}

resource "aws_iam_role_policy" "SSMRole" {
  name = "SSMRole"
  role = aws_iam_role.SSMRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "SSMRole-Attach" {
  role       = aws_iam_role.SSMRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ssm_activation" "SSM-ASG" {
  name               = "SSM_ASG_activation"
  description        = "SSMRole-Activation"
  iam_role           = aws_iam_role.SSMRole.id
  registration_limit = "5"
  depends_on         = [aws_iam_role_policy_attachment.SSMRole-Attach]
}

resource "aws_iam_instance_profile" "SSM-ASG" {
  name = "SSM-ASG"
  role = aws_iam_role.SSMRole.name
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "policy-attachment"
  roles      = [data.aws_iam_role.s3fullaccess.name, aws_iam_role.SSMRole.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_role" "s3fullaccess" {
  name = "s3fullaccess"
}
