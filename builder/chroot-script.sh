#!/bin/bash -e
set -x

# device specific settings
HYPRIOT_DEVICE="ODROID C1/C1+"

# set up /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# set up odroid repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB19BAC9
echo "deb http://deb.odroid.in/c1/ trusty main" > /etc/apt/sources.list.d/odroid.list
echo "deb http://deb.odroid.in/ trusty main" >> /etc/apt/sources.list.d/odroid.list

# set up hypriot schatzkiste repository
wget -q https://packagecloud.io/gpg.key -O - | apt-key add -
echo 'deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ wheezy main' > /etc/apt/sources.list.d/hypriot.list

apt-get update

# install odroid kernel
export DEBIAN_FRONTEND=noninteractive
apt-get install -y u-boot-tools initramfs-tools
# make the kernel package create a copy of the current kernel here
touch /boot/uImage
apt-get install -y linux-image-c1

# setup docker default configuration for ODROID C1
# --get upstream config
wget -q -O /etc/default/docker https://github.com/docker/docker/raw/master/contrib/init/sysvinit-debian/docker.default
# --enable aufs by default
sed -i '/#DOCKER_OPTS/a \
DOCKER_OPTS="--storage-driver=aufs -D"' /etc/default/docker

# install hypriot packages for using docker
set +e
apt-get install -y \
  docker-hypriot \
  docker-compose \
  docker-machine
set -e

# enable Docker systemd service
systemctl enable docker

# set device label
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
