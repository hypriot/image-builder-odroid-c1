#!/bin/bash

IMAGE_FILE=$1
DISK=disk2
DISK_DEVICE=/dev/$DISK

if [ ! -f "$IMAGE_FILE" ]; then
  echo "ERROR: can't find SD image file $IMAGE_FILE"
  exit 1
fi

echo "List all disk devices:"
df -h

echo ""
DF_ANSWER=$(df -h | grep $DISK_DEVICE)
if [ -z "$DF_ANSWER" ]; then
  echo "ERROR: can't find SD card device $DISK_DEVICE"
  exit 1
fi
while true; do
  echo "$DF_ANSWER"
  read -p "Is this your SD card device name? (y/N):" yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

echo "Unmounting ${DISK} ..."
diskutil unmountDisk /dev/${DISK}

IMAGE_SIZE=$(stat -f %z $IMAGE_FILE)
echo "Flashing SD image $IMAGE_FILE with size $IMAGE_SIZE ..."
cat $IMAGE_FILE | pv -s $IMAGE_SIZE | sudo dd bs=1m of=/dev/r$DISK

echo "Done."