#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd && systemctl enable httpd
echo "Hello DevOps" > /var/www/html/index.html
