# nodered test

Checking out Docker swarm orchestration framework.

Scope:
* First NodeRed flow simulates sensor and publishes events to mosquitto MQTT topic
* Second NodeRed flow subscribes to the MQTT topic and pushes measurements to InfluxDB
* Grafana dashboard shows the measurement history
* Data is stored on a Ceph storage cluster

# Conclusion

Docker swarm is nice easy-to use orchestration system. It has a clever overlay network mechanism. The service discovery is simple - service name == hostname. Load-balancing is built-in. Distribution of services amongst nodes can be controlled via labels.

There is no abstraction for distributed volumes, the storage must be set up and controlled manually. This might be a drawback in comparison with Kubernetes which has direct support for storage clusters like Ceph.

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
           ------+-----------------
           | Ceph Storage Cluster | 
           ------+-----------------
                 |
                 +------------------------------------- storage network (virtual)
                 |                                    |
           ------+------             |          ------+------
           | /dev/sda3 |             |          | /dev/sda3 |  physical partition
           -------------             |          -------------
                                     |
           host gigby-v01            |          host gigby-v02
```
