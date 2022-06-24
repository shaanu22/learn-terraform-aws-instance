data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance-type
  associate_public_ip_address = false
  key_name                    = aws_key_pair.ssh-key.id

  user_data = file("apache-script.sh")

  tags = {
    Name = "Hello-DevOps"
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}

output "aws_ami_id" {
  value = data.aws_ami.ubuntu.id
}

resource "aws_security_group" "allow_ingress" {
  name        = "allow_ssh-http"
  description = "Allow ssh-http inbound traffic"

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_address]
  }

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

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_launch_configuration" "ec2-launch-config" {
  name                        = "ec2-launch-config"
  image_id                    = data.aws_ami.ubuntu.id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.ssh-key.id
  instance_type               = var.instance-type
}

resource "aws_autoscaling_group" "hello-devOps" {
  name                      = "hello-devOps"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = aws_launch_configuration.ec2-launch-config.name
  vpc_zone_identifier       = [for s in data.aws_subnet.main_subnet : s.id]
  tag {
    key                 = "Name"
    value               = "hello-devOps"
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
  autoscaling_group_name = aws_autoscaling_group.hello-devOps.name
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
    AutoScalingGroupName = aws_autoscaling_group.hello-devOps.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.hello-devops.arn]
}

data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["DevOps_VPC"]
  }
}

output "vpc_id" {
  value = data.aws_vpc.main_vpc.id
}

data "aws_subnet" "main_subnet" {
  for_each = data.aws_subnet.main_subnet
  id       = each.value
  vpc_id   = var.vpc_id
}
