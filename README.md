# nodered test

Scope:
* First NodeRed flow simulates sensor and publishes events to mosquitto MQTT topic
* Second NodeRed flow subscribes to the MQTT topic and pushes measurements to InfluxDB
* Grafana dashboard shows the measurement history

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

The volumes are stored on distributed block devices (DRBD).