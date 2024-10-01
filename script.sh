#!/bin/bash

#should this be '/g' global?
sudo passwd --mindays 10 --maxdays 60

#no login as root
sudo passwd -l root

#check for nopasswd
# remove lines with these
# is this safe though?
sudo sed -i 's/.*(nopasswd|!authenticate).*//' /etc/sudoers

#set pam remember to 14
#try to replace the current value
old=$(< /etc/pam.d/common-password) 
sudo sed -i 's/pam_history[  ]\+remember[ ]*=[ ]*[0-9]*/pam_history.so remember=14/' /etc/pam.d/common-password
new=$(< /etc/pam.d/common-password) 
if [ "$new" == "$old" ];
then
  sudo echo "pam_history.so remember=14" >> /etc/pam.d/common-password
fi

#no blank passowrdss
sudo sed -i 's/nullok//g' /etc/pam.d/common-password

#remove uneccesary pkgs
sudo apt purge telnetd rsh-server
sudo apt autoremove

#ssh
#install
if [ -z "$(sudo dpkg -l | grep openssh)" ];
then
  sudo apt install ssh
  sudo systemctl enable sshd.service
  sudo systemctl start sshd.service
fi
#assumes spaces only (not tabs)
sudo sed -i 's/PermitRootLogin *yes/PermitRootLogin *no/' /etc/ssh/ssh_config

#syncookies
sudo sysctl -w -n net.ipv4.tcp-syncookies=1

#nginx
#
f=/etc/nginx/nginx.conf
old=$(< $f) 
sudo sed -i 's/add_header X-Frame-Options:.*/add_header X-Frame-Options: same origin always' $f
new=$(< $f) 
if [ "$new" == "$old" ];
then
  sudo echo "add_header X-Frame-Options: same origin always" >> $f
fi

#ctrl-alt-delete
sudo systemctl disable ctrl-alt-del.target
sudo systemctl mask ctrl-alt-del.target
sudo systemctl daemon-reload
#for gui
grep "(?<!#\w*)logout" /etc/dconf/db/local.d/*
if [ -z "$(grep -x 'logout.*' testing)" ];
then
  sudo printf "[org/gnome/settings-daemon/plugins/media-keys]\nlogout=''" > /etc/dconf/db/local.d/00-disable-CAD
fi

#update
sudo apt update
sudo apt upgrade
