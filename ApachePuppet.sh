#!/bin/bash
apt-get update -y
apt-get install -y httpd24 php56 mysql55-server php56-mysqlnd
service httpd start
chkconfig httpd on
groupadd www
usermod -a -G www ec2-user
chown -R root:www /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} +
find /var/www -type f -exec chmod 0664 {} +
echo "<hello-world>" > /var/www/html/hello.php
apt-get install -y puppet
echo "project.puppetagent1.com" > /etc/hostname
echo "master-ip-address project.puppetmaster.com" > /etc/hosts
echo "server=project.puppetmaster.com" > /etc/puppet/puppet.conf
