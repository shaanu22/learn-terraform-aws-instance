terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

    backend "s3" {
    bucket         = "s3-backend-bucket"
    key            = "compute.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.instance_value]
  }
  owners = ["amazon"]
}

data "terraform_remote_state" "network-config" {
  backend = "s3"

  config = {
    bucket = "s3-backend-bucket"
    key    = "network-config.tfstate"
    region = "us-east-1"
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow http inbound traffic"
  vpc_id      = data.terraform_remote_state.network-config.outputs.vpc_id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "instance_sg"
  }
}

resource "aws_launch_configuration" "ec2-launch-config" {
  name                        = "ec2-launch-config"
  image_id                    = data.aws_ami.amazon_linux.id
  associate_public_ip_address = false
  instance_type               = var.instance-type
  security_groups             = [aws_security_group.instance_sg.id]
  user_data                   = file("apache-script.sh")
  iam_instance_profile        = aws_iam_instance_profile.asg-roles.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "hello-devOps-asg" {
  name                      = "hello-devOps-asg"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = aws_launch_configuration.ec2-launch-config.name
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.elb-tg.arn]
  vpc_zone_identifier = [data.terraform_remote_state.network-config.outputs.private_subnets[0]
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "hello-devOps-asg"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_policy" "hello-devops" {
  name                   = "hello-devops"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 200
  autoscaling_group_name = aws_autoscaling_group.hello-devOps-asg.name
}

resource "aws_cloudwatch_metric_alarm" "hello-devops-alarm" {
  alarm_name          = "hello-devops-alarm"
  alarm_description   = "hello-devops-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.hello-devOps-asg.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.hello-devops.arn]
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.hello-devOps-asg.id
  alb_target_group_arn   = aws_lb_target_group.elb-tg.arn
}

output "aws_ami_id" {
  value = data.aws_ami.amazon_linux.id
}

resource "aws_security_group" "custom_elb_sg" {
  name   = "elb_sg"
  vpc_id = data.terraform_remote_state.network-config.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "elb_sg"
  }
}

resource "aws_lb" "custom-elb" {
  name               = "custom-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.custom_elb_sg.id]
  subnets            = data.terraform_remote_state.network-config.outputs.public_subnets[*]

  tags = {
    Name = "custom-elb"
  }
}

resource "aws_lb_target_group" "elb-tg" {
  name        = "elb-tg"
  target_type = "instance"
  protocol    = "HTTP"
  port        = 80
  vpc_id      = data.terraform_remote_state.network-config.outputs.vpc_id

  health_check {
    interval            = 15
    path                = "/"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 2
    port                = 80
  }

  tags = {
    Name = "elb-tg"
  }
}

resource "aws_lb_listener" "custom-elb" {
  load_balancer_arn = aws_lb.custom-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elb-tg.arn
  }
}

/*resource "aws_lb_target_group_attachment" "instance-tg" {
  target_group_arn = aws_lb_target_group.elb-tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}*/

resource "aws_iam_role" "asg-roles" {
  name = "asg-roles"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
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

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.asg-roles.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

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
  roles      = [aws_iam_role.s3fullaccess.name, aws_iam_role.SSMRole.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
