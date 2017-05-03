#!/bin/bash

sudo apt-get update
sudo apt-get install sysstat -y
sudo apt-get install nginx -y
sudo apt-get install apache2 -y
sudo apt-get install python3 -y
sudo rm -rf /etc/apache2/sites-available
sudo rm -rf /etc/apache2/sites-enabled
sudo rm -rf /etc/nginx/sites-available
sudo rm -rf /etc/nginx/sites-enabled
sudo mkdir /etc/apache2/sites-available
sudo mkdir /etc/apache2/sites-enabled
sudo mkdir /etc/nginx/sites-available
sudo mkdir /etc/nginx/sites-enabled
sudo cp src/sysinfo.conf /etc/apache2/sites-available
sudo ln -s /etc/apache2/sites-available/sysinfo.conf /etc/apache2/sites-enabled/sysinfo.conf
sudo cp src/BALinux.conf /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/BALinux.conf /etc/nginx/sites-enabled/BALinux.conf
sudo cp src/readTCPDUMP /var/www
sudo cp src/readIOSTAT /var/www
sudo cp src/SysRec.py /var/www
sudo chmod +x /var/www/readTCPDUMP
sudo chmod +x /var/www/readIOSTAT
sudo chmod +x /var/www/SysRec.py
sudo crontab src/MyCrontab
sudo service apache2 restart
sudo service nginx restart
