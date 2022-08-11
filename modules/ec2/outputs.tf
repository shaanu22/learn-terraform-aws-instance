output "instance_id" {
  value = aws_launch_configuration.ec2-launch-config.id
}

output "aws_ami_id" {
  value = data.aws_ami.amazon_linux.id
}

output "acm_cert" {
  value = aws_acm_certificate.acm_certificate.arn
}
