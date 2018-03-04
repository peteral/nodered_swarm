#!/bin/bash

# install ceph-deploy on admin node
sudo apt -y install ceph-deploy

# install prereqs on storage nodes
ssh gigby-v02 sudo apt -y install ntp python
ssh gigby-v03 sudo apt -y install ntp python
ssh gigby-v04 sudo apt -y install ntp python

# setup cluster
# prereq - unused block device /dev/sda3 on all nodes
mkdir my-cluster
cd my-cluster
ceph-deploy new gigby-v02
echo "public network = 192.168.2.0/24" | tee --append ceph.conf
ceph-deploy install gigby-v02 gigby-v03 gigby-v04
ceph-deploy mon create-initial
ceph-deploy admin gigby-v02 gigby-v03 gigby-v04
ceph-deploy mgr create gigby-v02
ceph-deploy osd create gigby-v02:/dev/sda3
ceph-deploy osd create gigby-v03:/dev/sda3
ceph-deploy osd create gigby-v04:/dev/sda3
ceph-deploy mds create gigby-v02
ceph-deploy mon add gigby-v03
ceph-deploy mon add gigby-v04
ceph-deploy mgr create gigby-v03 gigby-v04
ceph-deploy rgw create gigby-v02

# install ceph client on admin node
ceph-deploy install gigby-v01
ceph-deploy admin gigby-v01

# check status
sudo ceph -s

# every time I get here, all PGs are unknown

# create filesystem
sudo ceph osd pool create cephfs_data 128
sudo ceph osd pool create cephfs_metadata 128
ceph fs new cephfs cephfs_metadata cephfs_data
