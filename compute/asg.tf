resource "aws_launch_configuration" "ec2-launch-config" {
  name                        = "ec2-launch-config"
  image_id                    = data.aws_ami.ubuntu.id
  associate_public_ip_address = false
  key_name                    = "main"
  instance_type               = var.instance-type
  security_groups             = [aws_security_group.instance_sg.id]
  user_data = file("apache-script.sh")

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

data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["DevOps_VPC"]
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.hello-devOps-asg.id
  alb_target_group_arn   = aws_lb_target_group.elb-tg.arn
}
