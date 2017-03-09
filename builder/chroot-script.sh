#!/bin/bash
set -ex

# device specific settings
HYPRIOT_DEVICE="ODROID C1/C1+"

# set up /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# set up ODROID repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB19BAC9 D986B59D
echo "deb http://deb.odroid.in/c1/ xenial main" > /etc/apt/sources.list.d/odroid.list

# set up Hypriot Schatzkiste repository
wget -q https://packagecloud.io/gpg.key -O - | apt-key add -
echo 'deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ wheezy main' > /etc/apt/sources.list.d/hypriot.list

# Set up docker repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2C52609D
echo 'deb [arch=armhf] https://apt.dockerproject.org/repo debian-jessie main' > /etc/apt/sources.list.d/docker.list

# update all apt repository lists
export DEBIAN_FRONTEND=noninteractive
apt-get update 

# ---install Docker tools---
apt-get install -y \
  lxc \
  aufs-tools \
  cgroupfs-mount \
  cgroup-bin \
  apparmor \
  libltdl7 \
  "docker-engine=${DOCKER_ENGINE_VERSION}" \
  "docker-compose=${DOCKER_COMPOSE_VERSION}" \
  "docker-machine=${DOCKER_MACHINE_VERSION}" \
  --no-install-recommends

# install ODROID kernel
touch /boot/uImage
apt-get install -y \
  "u-boot-tools" \
  "initramfs-tools" \
  "linux-image-c1=${KERNEL_VERSION}"

# cleanup APT cache and lists
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set device label and version number
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
echo "HYPRIOT_IMAGE_VERSION=\"$HYPRIOT_IMAGE_VERSION\"" >> /etc/os-release
