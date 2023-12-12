vagrant plugin install virtualbox_WSL2

vim ~/.bashrc
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/Users/jpard/"
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox/"

Fix The IP address configured for the host-only network is not within the allowed ranges

vim /etc/vbox/networks.conf
* 10.0.0.0/8 192.168.0.0/16
* 2001::/64