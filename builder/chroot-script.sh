#!/bin/bash
set -ex

# device specific settings
HYPRIOT_DEVICE="ODROID C1/C1+"

# set up /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# set up ODROID repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB19BAC9
echo "deb http://deb.odroid.in/c1/ trusty main" > /etc/apt/sources.list.d/odroid.list
echo "deb http://deb.odroid.in/ trusty main" >> /etc/apt/sources.list.d/odroid.list

# set up Hypriot Schatzkiste repository
wget -q https://packagecloud.io/gpg.key -O - | apt-key add -
echo 'deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ wheezy main' > /etc/apt/sources.list.d/hypriot.list

# update all apt repository lists
export DEBIAN_FRONTEND=noninteractive
apt-get update

# ---install Docker tools---

# install Hypriot packages for using Docker
apt-get install -y \
  "docker-compose=${DOCKER_COMPOSE_VERSION}" \
  "docker-machine=${DOCKER_MACHINE_VERSION}"

# install ODROID kernel

apt-get install -y u-boot-tools initramfs-tools

# set up Docker APT repository and install docker-engine package
#TODO: pin package version to ${DOCKER_ENGINE_VERSION}
curl -sSL https://get.docker.com | /bin/sh

# make the kernel package create a copy of the current kernel here
touch /boot/uImage
apt-get install -y "linux-image-c1=${KERNEL_VERSION}"

# cleanup APT cache and lists
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set device label and version number
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
echo "HYPRIOT_IMAGE_VERSION=\"$HYPRIOT_IMAGE_VERSION\"" >> /etc/os-release
