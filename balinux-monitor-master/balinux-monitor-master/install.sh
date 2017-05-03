#!/bin/bash

uname="monitor"
passwd="monitor"

if [ "$1" != "--update" ] ; then
    # installing packages
    sudo apt install sysstat apache2 nginx nginx-core libcgi-pm-perl libjson-xs-perl libio-interface-perl

    # create monitor user adn add to staff group
    sudo adduser $uname
    echo $uname:$passwd | sudo chpasswd
    sudo usermod -a -G staff monitor

    # copy existing sudoers file
    sudo cp -f ./etc/sudoers.d/monitor /etc/sudoers.d/monitor
    sudo chmod 440 /etc/sudoers.d/monitor

    # copy configuration
    sudo cp -f ./etc/apache2/ports.conf /etc/apache2/ports.conf
    sudo cp -f ./etc/apache2/sites-avaliable/* /etc/apache2/sites-avaliable
    sudo cp -f ./etc/nginx/sites-avaliable/* /etc/nginx/sites-avaliable
    sudo ln -sf /etc/nginx/sites-avaliable/monitor /etc/nginx/sites-enabled/monitor

    # acrivating apache2 modules
    sudo ln -sf /etc/apache2/mods-available/cgid.load /etc/apache2/mods-enabled/
    sudo ln -sf /etc/apache2/mods-available/cgid.conf /etc/apache2/mods-enabled/

    # reload apache and nginx configuration
    sudo systemctl reload apache2.service
    sudo systemctl reload nginx.service
fi

# copy scripts and service files
sudo cp -rf ./scripts /home/$uname
sudo cp -rf ./systemd-units/* /etc/systemd/system
sudo cp -rf ./cgi-bin /var/
sudo chgrp staff /var/cgi-bin/
sudo chown monitor /var/cgi-bin/

# enabling systemd services
for systemd_unit in ./systemd-units/*; do
    sudo systemctl enable ${systemd_unit##*/}
    sudo systemctl start ${systemd_unit##*/}
done
