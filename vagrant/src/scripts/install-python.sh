#!/bin/bash

sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update

# Install Python 3.11
echo "Installing Python 3.11"
sudo apt-get install -y python3.11 python3.11-dev python3.11-venv python3.11-distutils
# Install pip
echo "Installing pip"
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11
# Alias python to python3.11
echo "Alias python to python3.11"
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
# Upgrade pip
echo "Upgrading pip"
python3.11 -m pip install --upgrade pip
