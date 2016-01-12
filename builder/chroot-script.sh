#!/bin/bash -e
set -x

# device specific settings
HYPRIOT_DEVICE="ODROID C1"

# set up /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# set up odroid repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB19BAC9
echo "deb http://deb.odroid.in/c1/ trusty main" > /etc/apt/sources.list.d/odroid.list
echo "deb http://deb.odroid.in/ trusty main" >> /etc/apt/sources.list.d/odroid.list

apt-get update

# install odroid kernel
export DEBIAN_FRONTEND=noninteractive
apt-get install -y u-boot-tools initramfs-tools
# make the kernel package create a copy of the current kernel here
touch /boot/uImage
apt-get install -y linux-image-c1

# set device label
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
