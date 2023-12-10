#!/bin/bash

# Set the Spanish keyboard layout
sudo sed -i 's/XKBLAYOUT="us"/XKBLAYOUT="es"/' /etc/default/keyboard
sudo dpkg-reconfigure -f noninteractive keyboard-configuration
sudo service keyboard-setup restart
