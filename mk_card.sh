#! /bin/sh
# mkcard.sh v0.5
# (c) Copyright 2009 Graeme Gregory <dp@xora.org.uk>
# Licensed under terms of GPLv2
#
# Parts of the procudure base on the work of Denys Dmytriyenko
# http://wiki.omap.com/index.php/MMC_Boot_Format
#
# Modified by Zakharchenko Taras
# 

export LC_ALL=C

if [ $# -ne 1 ]; then
	echo "Usage: $0 <drive>"
	exit 1;
fi

DRIVE=$1

if [ "0" -ne `id -u` ]; then
	echo "Only root can execute this"
	exit 1;
fi



SIZE=`fdisk -l $DRIVE | grep Disk | grep bytes | awk '{print $5}'`

echo DISK SIZE - $SIZE bytes

CYLINDERS=`echo $SIZE/255/63/512 | bc`

echo CYLINDERS - $CYLINDERS
let ROOTSZ=$CYLINDERS-16

#Clear first 256MB data on FLASH
echo Clearing data on flash
dd if=/dev/zero of=$DRIVE bs=1M count=256

echo Cretaing boot partition
echo ",15,0x0C,* 
16,$ROOTSZ,0x83,"| sfdisk -D -H 255 -S 63 -C $CYLINDERS $DRIVE 
#It doesn't work on my Debian 8.6, you can't use sfdisk with such keys there, so I did it using fdisk. 

sleep 1

echo Formatting boot partition
PARTITION1=${DRIVE}1
if [ ! -b ${PARTITION1} ]; then
	PARTITION1=${DRIVE}p1
fi

if [ -b ${PARTITION1} ]; then
	mkfs.vfat -F 32 -n "boot" ${PARTITION1}
else
	echo "Cant find boot partition in /dev"
fi

echo Formatting rootfs partition
PARTITION2=${DRIVE}2
if [ ! -b ${PARTITION2} ]; then
	PARTITION1=${DRIVE}p2
fi

if [ -b ${PARTITION2} ]; then
	mkfs.ext3 ${PARTITION2}
else
	echo "Cant find boot partition in /dev"
fi

