#!/bin/bash
yum update -y
yum install -y httpd wget unzip
systemctl start httpd
systemctl enable httpd
cd /tmp
wget https://www.tooplate.com/zip-templates/2150_living_parallax.zip
unzip -o 2150_living_parallax.zip
cp -r 2150_living_parallax/* /var/www/html/
chown -R apache:apache /var/www/html/
