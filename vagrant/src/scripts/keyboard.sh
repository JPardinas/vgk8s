#!/bin/bash

# argument 1 is keyboard layout
layout=$1

echo "Setting keyboard layout to $layout"
sudo sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="'$layout'"/g' /etc/default/keyboard
sudo dpkg-reconfigure -f noninteractive keyboard-configuration
sudo service keyboard-setup restart
