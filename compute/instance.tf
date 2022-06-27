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
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_ids
  security_groups             = [aws_security_group.instance_sg.id]
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

output "instance_id" {
  description = "instance ID"
  value       = aws_instance.web.id
}

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow ssh-http inbound traffic"
  vpc_id      = data.aws_subnet.selected.vpc_id

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

data "aws_subnet" "selected" {
  id = var.subnet_ids
}
