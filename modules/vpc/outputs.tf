output "vpc_id" {
  description = "VPC ID for subnets"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

/*output "cidr_vpc" {
  value = aws_vpc.main.my_vpc_cidr.id
}*/