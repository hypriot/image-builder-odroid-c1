#!/bin/bash -e
set -x

# device specific settings
HYPRIOT_DEVICE="ODROID C1"

# set up /etc/resolv.conf
DEST=$(readlink -m /etc/resolv.conf)
mkdir -p "$(dirname "${DEST}")"
echo "nameserver 8.8.8.8" > "${DEST}"

# set up odroid repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB19BAC9
echo "deb http://deb.odroid.in/c1/ trusty main" > /etc/apt/sources.list.d/odroid.list
echo "deb http://deb.odroid.in/ trusty main" >> /etc/apt/sources.list.d/odroid.list

# install parted (for online disk resizing)
apt-get update
apt-get install -y parted

# install odroid kernel
export DEBIAN_FRONTEND=noninteractive
apt-get install -y u-boot-tools initramfs-tools
apt-get install -y linux-image-c1

# set device label
echo "HYPRIOT_DEVICE=\"${HYPRIOT_DEVICE}\"" >> /etc/os-release
