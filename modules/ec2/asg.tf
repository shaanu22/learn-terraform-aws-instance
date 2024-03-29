data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
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
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.instance_sg.id]
  user_data                   = file("apache-script.sh")
  iam_instance_profile        = aws_iam_instance_profile.SSM-ASG.name

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
