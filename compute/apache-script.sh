#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd && systemctl enable httpd
echo "DevOps Is Awesome!" > /var/www/html/index.html
