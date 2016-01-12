#!/bin/bash -e
set -x

# device specific settings
HYPRIOT_DEVICE="ODROID C1"
HYPRIOT_GROUPNAME="docker"
HYPRIOT_USERNAME="pirate"
HYPRIOT_PASSWORD="hypriot"

# set up /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# set up odroid repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB19BAC9
echo "deb http://deb.odroid.in/c1/ trusty main" > /etc/apt/sources.list.d/odroid.list
echo "deb http://deb.odroid.in/ trusty main" >> /etc/apt/sources.list.d/odroid.list

apt-get update

#FIXME: has to be moved to hypriot/os-rootfs
# upgrade to latest Debian package versions
apt-get upgrade -y

#FIXME: has to be moved to hypriot/os-rootfs
# install parted (for online disk resizing)
apt-get install -y parted

#FIXME: has to be moved to hypriot/os-rootfs
# install sudo (for our default user)
apt-get install -y sudo

# install odroid kernel
export DEBIAN_FRONTEND=noninteractive
apt-get install -y u-boot-tools initramfs-tools
# make the kernel package create a copy of the current kernel here
touch /boot/uImage
apt-get install -y linux-image-c1

# install Hypriot group and user
addgroup --system --quiet $HYPRIOT_GROUPNAME
useradd -m $HYPRIOT_USERNAME --group $HYPRIOT_GROUPNAME --shell /bin/bash
echo "$HYPRIOT_USERNAME:$HYPRIOT_PASSWORD" | /usr/sbin/chpasswd
# add user to sudoers group
echo "$HYPRIOT_USERNAME ALL=NOPASSWD: ALL" > /etc/sudoers.d/user-$HYPRIOT_USERNAME
chmod 0440 /etc/sudoers.d/user-$HYPRIOT_USERNAME

#FIXME: has to be removed in hypriot/os-rootfs
# disable SSH root login
sed -i 's|PermitRootLogin yes|PermitRootLogin without-password|g' /etc/ssh/sshd_config
# remove/disable root password
passwd -d root

# set device label
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
