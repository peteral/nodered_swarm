#!/bin/bash
apt-get install -y drbd8-utils ntp

# add new partition with fdisk
pvcreate /dev/sda2
vgextend gigby-v01-vg /dev/sda2
lvcreate -L 5G -n nodered gigby-v01-vg
#mkfs.ext4 /dev/gigby-v01-vg/nodered
if=/dev/zero of=/dev/gigby-v01-vg/nodered
