
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  /*data "aws_vpc" "main" {
    name = "DevOps_VPC"
  }*/

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

/*data "aws_subnet" "private" {
  cidr_block = var.private_cidr[count.index]
}*/

data "local_file" ""private_cidr" {
    filename = "${network-config/main.tf.module}"
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
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

resource "aws_launch_configuration" "ec2-launch-config" {
  name          = "ec2-launch-config"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance-type
}

resource "aws_security_group" "allow_ingress" {
  name        = "allow_ssh-http"
  description = "Allow ssh-http inbound traffic"
  #vpc_id      = aws_vpc.main.id


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

# Create a new load balancer
resource "aws_elb" "load-balancer" {
  name               = "load-balancer"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  /*access_logs {
    bucket        = "foo"
    bucket_prefix = "bar"
    interval      = 60
  }*/

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  /*listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }*/

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_instance.web.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 200
  connection_draining         = true
  connection_draining_timeout = 200

  tags = {
    Name = "load-balancer"
  }
}

resource "aws_placement_group" "ec2-placement-group" {
  name     = "ec2-placement-group"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "autoscaling-group" {
  name                      = "autoscaling-group"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  placement_group           = aws_placement_group.ec2-placement-group.id
  launch_configuration      = aws_launch_configuration.ec2-launch-config.id
  #vpc_zone_identifier       = [aws_subnet.example1.id, aws_subnet.example2.id]

  /*initial_lifecycle_hook {
    name                 = "autoscaling-group"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = <<EOF
{
  "foo": "bar"
}
EOF

    notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
    role_arn                = "arn:aws:iam::123456789012:role/S3Access"
  }

  tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }*/

  tag {
    key                 = "Name"
    value               = "autoscaling-group"
    propagate_at_launch = true
  }
}

