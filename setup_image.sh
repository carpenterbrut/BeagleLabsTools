#!/bin/bash

IMAGE=$1
DISK=$2

FAT_MP=/tmp/fat
EXT_MP=/tmp/ext
FAT_DISK_MP=/tmp/disk_fat
EXT_DISK_MP=/tmp/disk_ext

#Check if root
if [ "0" -ne `id -u` ]; then
	echo "Only root can execute this"
	exit 1;
fi

#Determine partitions offset
PARTITIONS=$(parted -s $IMAGE unit b print | grep  -o -P "\d\s+(\d+)B" | sed \
	's/B//g' | sed 's/^[1-9]\s*//g')

FAT_OFFSET=$(echo $PARTITIONS | cut -d ' ' -f 1)
EXT_OFFSET=$(echo $PARTITIONS | cut -d ' ' -f 2)

#Mount image partitions
mkdir -p $FAT_MP
mkdir -p $EXT_MP
mount -o loop,offset=$FAT_OFFSET $IMAGE $FAT_MP
mount -o loop,offset=$EXT_OFFSET $IMAGE $EXT_MP

#Format disk
./mk_card.sh $DISK

#Mount disk partitions
mkdir -p $FAT_DISK_MP
mkdir -p $EXT_DISK_MP
mount $DISK"1" $FAT_DISK_MP
mount $DISK"2" $EXT_DISK_MP

#Copy data
#First copy MLO!
cp $FAT_MP/MLO $FAT_DISK_MP
cp -f -r -p -P $FAT_MP/* $FAT_DISK_MP
cp -f -r -p -P $EXT_MP/* $EXT_DISK_MP

#Unmount image partitions
umount $FAT_MP
rm -rf $FAT_MP
umount $EXT_MP
rm -rf $EXT_MP

#Unmount disk partiotions 
umount $FAT_DISK_MP
rm -rf $FAT_DISK_MP
umount $EXT_DISK_MP
rm -rf $EXT_DISK_MP
