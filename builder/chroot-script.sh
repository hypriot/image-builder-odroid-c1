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
echo 'deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ jessie main' > /etc/apt/sources.list.d/hypriot.list

# Set up docker repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2C52609D
echo 'deb [arch=armhf] https://apt.dockerproject.org/repo debian-jessie main' > /etc/apt/sources.list.d/docker.list

# update all apt repository lists
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# define packages to install
packages=(
    # as the Odroid C1/C1+ does not have a hardware clock we need a fake one
    fake-hwclock

    # install device-init
    device-init=${DEVICE_INIT_VERSION}

    # install dependencies for docker-tools
    cgroupfs-mount \
    cgroup-bin \
    libltdl7 \

    # required to install docker-compose
    python-pip

    # install docker-engine, docker-machine
    docker-engine="${DOCKER_ENGINE_VERSION}"
)

apt-get -y install --no-install-recommends ${packages[*]}

# install docker-compose
pip install docker-compose=="${DOCKER_COMPOSE_VERSION}"

# install docker-machine
curl -L "https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine-$(uname -s)-$(dpkg --print-architecture)" > /usr/local/bin/docker-machine
chmod +x /usr/local/bin/docker-machine

# install ODROID kernel
touch /boot/uImage
apt-get install -y \
    --no-install-recommends \
    u-boot-tools \
    initramfs-tools \
    linux-image-"${KERNEL_VERSION}"

# cleanup APT cache and lists
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set device label and version number
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
echo "HYPRIOT_IMAGE_VERSION=\"$HYPRIOT_IMAGE_VERSION\"" >> /etc/os-release
