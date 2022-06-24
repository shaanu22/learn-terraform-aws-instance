resource "aws_lb_target_group" "hello-devops" {
  health_check {
    interval            = 120
    path                = "/"
    protocol            = "HTTP"
    timeout             = 100
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "hello-devops"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
}

resource "aws_elb" "load-balancer" {
  name = "load-balancer"
  #vpc_id             = var.my_vpc_cidr
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  #availability_zones = data.aws_availability_zones.available.names

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

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
