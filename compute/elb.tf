resource "aws_security_group" "elb_sg" {
  name   = "elb_sg"
  vpc_id = var.vpc_id

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

resource "aws_lb" "elb" {
  name               = "elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.instance_sg.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "custom-elb"
  }
}

resource "aws_lb_target_group" "elb-tg" {
  name        = "elb-tg"
  target_type = "instance"
  port        = 80
  vpc_id      = var.vpc_id

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
    Name = "elb_target_group"
  }
}

resource "aws_lb_target_group_attachment" "instance-tg" {
  target_group_arn = aws_lb_target_group.elb-tg.arn
  target_id        = var.instance_id
  port             = 80
}
