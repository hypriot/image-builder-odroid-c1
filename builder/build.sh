#!/bin/bash
set -ex
# This script should be run only inside of a Docker container
if [ ! -f /.dockerenv ]; then
  echo "ERROR: script works only in a Docker container!"
  exit 1
fi

# get versions for software that needs to be installed
source /workspace/versions.config

### setting up some important variables to control the build process

# where to store our created sd-image file
BUILD_RESULT_PATH="/workspace"

# place to build our sd-image
BUILD_PATH="/build"

ROOTFS_TAR="rootfs-armhf-debian-${HYPRIOT_OS_VERSION}.tar.gz"
ROOTFS_TAR_PATH="$BUILD_RESULT_PATH/$ROOTFS_TAR"

# Show TRAVSI_TAG in travis builds
echo TRAVIS_TAG="${TRAVIS_TAG}"

# size of root and boot partion
ROOT_PARTITION_SIZE="800M"

# device specific settings
HYPRIOT_IMAGE_VERSION=${VERSION:="dirty"}
HYPRIOT_IMAGE_NAME="hypriotos-odroid-c1-${HYPRIOT_IMAGE_VERSION}.img"
IMAGE_ROOTFS_PATH="/image-rootfs.tar.gz"
QEMU_ARCH="arm"
export HYPRIOT_IMAGE_VERSION

# create build directory for assembling our image filesystem
rm -rf ${BUILD_PATH}
mkdir ${BUILD_PATH}

# download our base root file system
if [ ! -f "${ROOTFS_TAR_PATH}" ]; then
  wget -q -O "${ROOTFS_TAR_PATH}" "https://github.com/hypriot/os-rootfs/releases/download/${HYPRIOT_OS_VERSION}/${ROOTFS_TAR}"
fi

# verify checksum of our root filesystem
echo "${ROOTFS_TAR_CHECKSUM} ${ROOTFS_TAR_PATH}" | sha256sum -c -

# extract root file system
tar xf "${ROOTFS_TAR_PATH}" -C "${BUILD_PATH}"

# register qemu-arm with binfmt
update-binfmts --enable qemu-$QEMU_ARCH

# set up mount points for the pseudo filesystems
mkdir -p ${BUILD_PATH}/{proc,sys,dev/pts}

mount -o bind /dev ${BUILD_PATH}/dev
mount -o bind /dev/pts ${BUILD_PATH}/dev/pts
mount -t proc none ${BUILD_PATH}/proc
mount -t sysfs none ${BUILD_PATH}/sys

# modify/add image files directly
# e.g. root partition resize script
cp -R /builder/files/* ${BUILD_PATH}/

# make our build directory the current root
# and install the kernel packages, docker tools
# and some customizations for Odroid C2.
chroot $BUILD_PATH /bin/bash < /builder/chroot-script.sh

# unmount pseudo filesystems
umount -l $BUILD_PATH/sys
umount -l $BUILD_PATH/proc
umount -l $BUILD_PATH/dev/pts
umount -l $BUILD_PATH/dev

# package image rootfs
tar -czf $IMAGE_ROOTFS_PATH -C $BUILD_PATH .

# package image filesytem into two tarballs - one for bootfs and one for rootfs
# ensure that there are no leftover artifacts in the pseudo filesystems
rm -rf ${BUILD_PATH}/{dev,sys,proc}/*

# create the image and add a single ext4 filesystem
# --- important settings for ODROID SD card
# - initialise the partion with MBR
# - use start sector 3072, this reserves 1.5MByte of disk space
# - don't set the partition to "bootable"
# - format the disk with ext4
# for debugging use 'set-verbose true'
#set-verbose true

#FIXME: use latest upstream u-boot files from hardkernel
# download current bootloader/u-boot images from hardkernel
wget -q https://raw.githubusercontent.com/mdrjr/c1_uboot_binaries/master/bl1.bin.hardkernel
wget -q https://raw.githubusercontent.com/mdrjr/c1_uboot_binaries/master/u-boot.bin

guestfish <<EOF
# create new image disk
sparse /$HYPRIOT_IMAGE_NAME $ROOT_PARTITION_SIZE
run
part-init /dev/sda mbr
part-add /dev/sda primary 3072 -1
part-set-bootable /dev/sda 1 false
mkfs ext4 /dev/sda1

# import base rootfs
mount /dev/sda1 /
tar-in $IMAGE_ROOTFS_PATH / compress:gzip

#FIXME: use dd to directly writing u-boot to image file
#FIXME2: later on, create a dedicated .deb package to install/update u-boot
# write bootloader and u-boot into image start sectors 0-3071
upload bl1.bin.hardkernel /boot/bl1.bin.hardkernel
upload u-boot.bin /boot/u-boot.bin
upload /builder/boot.ini /boot/boot.ini
copy-file-to-device /boot/bl1.bin.hardkernel /dev/sda size:442 sparse:true
copy-file-to-device /boot/bl1.bin.hardkernel /dev/sda srcoffset:512 destoffset:512 sparse:true
copy-file-to-device /boot/u-boot.bin /dev/sda destoffset:32768 sparse:true
EOF

# log image partioning
fdisk -l "/$HYPRIOT_IMAGE_NAME"

# ensure that the travis-ci user can access the SD card image file
umask 0000

# compress image
zip "${BUILD_RESULT_PATH}/${HYPRIOT_IMAGE_NAME}.zip" "${HYPRIOT_IMAGE_NAME}"
cd ${BUILD_RESULT_PATH} && sha256sum "${HYPRIOT_IMAGE_NAME}.zip" > "${HYPRIOT_IMAGE_NAME}.zip.sha256" && cd -

# test sd-image that we have built
VERSION=${HYPRIOT_IMAGE_VERSION} rspec --format documentation --color /builder/test
