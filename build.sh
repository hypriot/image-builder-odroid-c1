#!/bin/bash -e
set -x
# This script should be run only inside of a Docker container
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works only in a Docker container!"
  exit 1
fi

### setting up some important variables to control the build process

# device specific settings
IMAGE_NAME="sd-card-odroid-c1.img"
IMAGE_ROOTFS_PATH="/image-rootfs.tar.gz"
QEMU_ARCH="arm"

# where to store our created sd-image file
BUILD_RESULT_PATH="/workspace"
BUILD_PATH="/build"

# where to store our base file system
ROOTFS_TAR="rootfs-armhf.tar.gz"
ROOTFS_TAR_PATH="${BUILD_RESULT_PATH}/${ROOTFS_TAR}"

# what kernel to use
KERNEL_DATETIME=${KERNEL_DATETIME:="20151103-193133"}
KERNEL_VERSION=${KERNEL_VERSION:="4.1.12"}

# size of root and boot partion
ROOT_PARTITION_SIZE="800M"

# create build directory for assembling our image filesystem
rm -rf "${BUILD_PATH}"
mkdir -p "${BUILD_PATH}"

# download our base root file system
if [ ! -f "${ROOTFS_TAR_PATH}" ]; then
  wget -q -O ${ROOTFS_TAR_PATH} https://github.com/hypriot/os-rootfs/releases/download/v0.4/${ROOTFS_TAR}
fi

# extract root file system
tar -xzf "${ROOTFS_TAR_PATH}" -C "${BUILD_PATH}"

# register qemu-arm with binfmt
update-binfmts --enable qemu-"${QEMU_ARCH}"

# set up mount points for pseudo filesystems
mkdir -p "${BUILD_PATH}/{proc,sys,dev/pts}"

mount -o bind /dev "${BUILD_PATH}/dev"
mount -o bind /dev/pts "${BUILD_PATH}/dev/pts"
mount -t proc none "${BUILD_PATH}/proc"
mount -t sysfs none "${BUILD_PATH}/sys"

# make our build directory the current root
# and install additional packages
chroot ${BUILD_PATH} /bin/bash <<"EOF"
# set up /etc/resolv.conf
export DEST=$(readlink -m /etc/resolv.conf)
mkdir -p $(dirname $DEST)
echo "nameserver 8.8.8.8" > $DEST

# install parted (for online disk resizing)
apt-get update
apt-get install -y parted

# set device label
echo 'HYPRIOT_DEVICE="ODROID C1"' >> /etc/os-release
exit
EOF

umount -l "${BUILD_PATH}/dev/pts" || true
umount -l "${BUILD_PATH}/dev" || true
umount -l "${BUILD_PATH}/proc" || true
umount -l "${BUILD_PATH}/sys" || true

# package image rootfs
tar -czf "${IMAGE_ROOTFS_PATH}" -C "${BUILD_PATH}" .

# create the image and add a single ext4 filesystem
# --- important settings for NVIDIA ShieldTV SD card
# - initialise the partion with MBR
# - use start sector 2048, this reserves 1MByte of disk space
# - don't set the partition to "bootable"
# - format the disk with ext4
# for debugging use 'set-verbose true'
#set-verbose true
guestfish <<EOF
# create new image disk
sparse /${IMAGE_NAME} ${ROOT_PARTITION_SIZE}
run
part-init /dev/sda mbr
part-add /dev/sda primary 2048 -1
part-set-bootable /dev/sda 1 false
mkfs ext4 /dev/sda1

# import base rootfs
mount /dev/sda1 /
tar-in "${IMAGE_ROOTFS_PATH}" / compress:gzip
EOF

# log image partioning
fdisk -l /${IMAGE_NAME}

# test sd-image that we have built
rspec --format documentation --color /test

# ensure that the travis-ci user can access the sd-card image file
umask 0000

# compress image
pigz --zip -c "${IMAGE_NAME}" > "${BUILD_RESULT_PATH}/${IMAGE_NAME}.zip"
