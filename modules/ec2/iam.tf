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

resource "aws_iam_role_policy_attachment" "SSMRole-Attach" {
  role       = aws_iam_role.SSMRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "SSM-ASG" {
  name = "SSM-ASG"
  role = aws_iam_role.SSMRole.name
}
