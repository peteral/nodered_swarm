#!/bin/bash
apt-get install -y drbd8-utils ntp

# add new partition with fdisk
pvcreate /dev/sda2
vgextend gigby-v01-vg /dev/sda2
lvcreate -L 5G -n nodered gigby-v01-vg
dd if=/dev/zero of=/dev/gigby-v01-vg/nodered

# setup storage network
# gigby-v01
ifconfig enp0s3:0 192.168.210.1
# gigby-v02
ifconfig enp0s3:0 192.168.210.2

# setup drbd resource on both nodes
drbdadm create-md nodered

# enable resource on both nodes
drbdadm up nodered

# double check
cat /proc/drbd
drbd-overview

# select primary resource on one node
drbdadm primary --force nodered

# format device on primary node
mkfs.ext4 /dev/drbd1

# mount volume
mkdir /mnt/drbd1
mount /dev/drbd1 /mnt/drbd1

# initial setup
mkdir /mnt/drbd1/nodered
mkdir /mnt/drbd1/influxdb
mkdir /mnt/drbd1/grafana

# adjusting resources after config change on both nodes
drbdadm adjust nodered
