resource "aws_launch_configuration" "ec2-launch-config" {
  name          = "ec2-launch-config"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance-type
}

resource "aws_autoscaling_group" "hello-devOps" {
  name                      = "Hello-DevOps"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = aws_launch_configuration.ec2-launch-config.name
  vpc_zone_identifier       = ["${data.aws_availability_zones.elb-ec2-az.id}"]

  tag {
    key                 = "Name"
    value               = "Hello-DevOps"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}
