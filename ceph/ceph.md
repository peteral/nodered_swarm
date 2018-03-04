# Ceph

[http://docs.ceph.com/docs/master/]

# Introduction

Ceph provides 3 types of distributed storage:
* object storage (Rest-APIs)
* block storage
* POSIX file system

Components:
* **ceph-osd** - object storage daemon - stores data, handles data replication, recovery, rebalancing, and provides some monitoring information to Ceph Monitors and Managers by checking other Ceph OSD Daemons for a heartbeat. At least 3 Ceph OSDs are normally required for redundancy and high availability.
* **ceph-mon** - monitor - maintains maps of the cluster state, , including the monitor map, manager map, the OSD map, and the CRUSH map. These maps are critical cluster state required for Ceph daemons to coordinate with each other. Monitors are also responsible for managing authentication between daemons and clients. At least three monitors are normally required for redundancy and high availability.
* **ceph-mgr** - manager - responsible for keeping track of runtime metrics and the current state of the Ceph cluster, including storage utilization, current performance metrics, and system load. The Ceph Manager daemons also host python-based plugins to manage and expose Ceph cluster information, including a web-based dashboard and REST API. At least two managers are normally required for high availability.
* **ceph-mds** - metadata server - stores metadata on behalf of the Ceph Filesystem (i.e., Ceph Block Devices and Ceph Object Storage do not use MDS). Ceph Metadata Servers allow POSIX file system users to execute basic commands (like ls, find, etc.) without placing an enormous burden on the Ceph Storage Cluster.
* **client** - different client approaches for different storage types, the file system storage client is implemented as kernel module.