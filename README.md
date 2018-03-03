# nodered test

Checking out Docker swarm orchestration framework.

Scope:
* First NodeRed flow simulates sensor and publishes events to mosquitto MQTT topic
* Second NodeRed flow subscribes to the MQTT topic and pushes measurements to InfluxDB
* Grafana dashboard shows the measurement history

# Conclusion

Docker swarm is nice easy-to use orchestration system. It has a clever overlay network mechanism. The service discovery is simple - service name == hostname. Load-balancing is built-in. Distribution of services amongst nodes can be controlled via labels.

The biggest drawback is no solution for distributed volumes and therefore failover of statefull services. Configuration data might be embedded into the docker image or mounted via NFS. However implementing databases this way will become a bit problematic.

Following approach might work:
* dedicated **datacenter** nodes possess shared storage
  * either via fail-over (Pacemaker, GFS, DRBD)
  * or distributed file system like Ceph, MooseFS

# how to run

Start:
```
docker swarm init
./setup.sh
```

Access:
* NodeRed: [http://docker-host]
* Grafana: [http://docker-host:3000]

# network
```
------------          ---------+---------
| registry |          | docker_gwbridge |
-----+------          ---------+---------
     | 5000                    |
-----+---------------+---------+----+-------------+----- nodered
     | 80            | 1883, 9001   | 8086        | 3000
-----+-----   -------+-----   ------+-----   -----+-----
| nodered |   | mosquitto |   | influxdb |   | grafana |
-----------   -------------   ------------   -----------
```

# storage

```
                                    docker service
            -----------         -----------                -----------
            | nodered |         | nodered |                | nodered | 
            -----+-----         -----+-----                -----+-----
                 |                   |                          |
      -----------+----------  -------+---------------  ----------+-----------
      | /mnt/drbd1/nodered |  | /mnt/drbd1/influxdb |  | /mnt/drbd1/grafana | 
      -----------+----------  -------+---------------  ----------+-----------
                 |                   |                          |
                 +-------------------+---------------------------
                 |                                    
           ------+-------
           | /dev/drdb1 | DRBD volume (dual primary mode)
           ------+-------
                 |
                 +------------------------------------- storage network (virtual)
                 |                                    |
    -------------+---------------    |   -------------+---------------
    | /dev/gigby-v01-vg/nodered |    |   | /dev/gigby-v01-vg/nodered | LVM vol. 
    -------------+---------------    |   -------------+---------------
                 |                   |                |
           ------+------             |          ------+------
           | /dev/sda2 |             |          | /dev/sda2 |  physical partition
           -------------             |          -------------
                                     |
           host gigby-v01            |          host gigby-v02
```

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