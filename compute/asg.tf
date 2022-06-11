resource "aws_autoscaling_group" "autoscaling-group" {
  name                      = "autoscaling-group"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = aws_launch_configuration.ec2-launch-config.name
  vpc_zone_identifier       = ["subnet-06a635987b7305b12"]

  tag {
    key                 = "Name"
    value               = "Hello-DevOps"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "Name"
    value               = "autoscaling-group"
    propagate_at_launch = true
  }
}
