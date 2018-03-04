# DRBD

The configuration data is stored in docker volumes which are in turn stored on a distributed block device (DRBD).
DRBD only supports one replication between two hosts so it can be used for disaster recovery / failover of a service to a second node. (Although there is an option for multinode setups using resource stacking)
It is however not a full distributed file system like Ceph or MooseFS.
The resource is in one the following states:
* primary - mounted, readable and writable
* secondary - being synced, but not readable or writable. Can be promoted to primary

Operating modes:
* **single primary**
  * resource in primary state only on one node
  * fail-over scenarios
  * can be used with any conventional file system like ext4
* **dual primary**
  * In dual-primary mode, a resource is, at any given time, in the primary role on both cluster nodes. 
  * Since concurrent access to the data is thus possible, this mode requires the use of a shared cluster file system that utilizes a distributed lock manager. Examples include GFS and OCFS2.
  * preferred approach for load-balancing clusters which require concurrent data access from two nodes. This mode is disabled by default, and must be enabled explicitly in DRBD’s configuration file.
* **replicated**
  * **Protocol A**
    * Asynchronous replication protocol. 
    * Local write operations on the primary node are considered completed as soon as the local disk write has finished, and the replication packet has been placed in the local TCP send buffer. 
    * In the event of forced fail-over, data loss may occur. The data on the standby node is consistent after fail-over, however, the most recent updates performed prior to the crash could be lost. 
    * Protocol A is most often used in long distance replication scenarios. When used in combination with DRBD Proxy it makes an effective disaster recovery solution.
  * **Protocol B**
    * Memory synchronous (semi-synchronous) replication protocol. 
    * Local write operations on the primary node are considered completed as soon as the local disk write has occurred, and the replication packet has reached the peer node. 
    * Normally, no writes are lost in case of forced fail-over. However, in the event of simultaneous power failure on both nodes and concurrent, irreversible destruction of the primary’s data store, the most recent writes completed on the primary may be lost.
  * **Protocol C**
    * Synchronous replication protocol. 
    * Local write operations on the primary node are considered completed only after both the local and the remote disk write have been confirmed. 
    * As a result, loss of a single node is guaranteed not to lead to any data loss. Data loss is, of course, inevitable even with this replication protocol if both nodes (or their storage subsystems) are irreversibly destroyed at the same time.
    * By far, the most commonly used replication protocol in DRBD setups is protocol C.

Following automatic algorithms are available as resolution for a split brain scenario:
* Discarding modifications made on the younger primary. 
* Discarding modifications made on the older primary. 
* Discarding modifications on the primary with fewer changes. 
* Graceful recovery from split brain if one host has had no intermediate changes. In this mode, if one of the hosts has made no modifications at all during split brain, DRBD will simply recover gracefully and declare the split brain resolved. Note that this is a fairly unlikely scenario. Even if both hosts only mounted the file system on the DRBD block device (even read-only), the device contents would be modified, ruling out the possibility of automatic recovery.

Problem of the **primary/secondary** setup:
* Failover must be performed manually, device can only be mounted on one node.
  ```bash
  # on node 1
  unmount /dev/drbd/by-res/nodered
  drbdadm secondary nodered

  # on node 2
  drbdadm primary nodered
  mount /dev/drbd/by-res/nodered /mnt/drbd1
  ```

**Double-primary setup**
* is basically building a failover cluster
* lt's have a look if other orchestration frameworks have some own abstraction for distributed volumes