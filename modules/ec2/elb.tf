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
