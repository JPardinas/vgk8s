#!/bin/bash

# Install Python 3.11
echo "Installing Python 3.11"
sudo apt-get install -y python3.11 python3.11-dev python3.11-venv python3.11-distutils
# Install pip
echo "Installing pip"
sudo apt-get install -y python3-pip
# Alias python to python3.11
echo "Alias python to python3.11"
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
# Alias python3 to python3.11
echo "Alias python3 to python3.11"
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
# Upgrade pip
echo "Upgrading pip as vagrant user"
pip3 install --upgrade pip
echo "Upgrading pip (sudo)"
sudo pip3 install --upgrade pip
