#!/bin/bash
# ---------------------------------------------------------
# prerequisites - initialized swarm
# docker swarm init
# ---------------------------------------------------------
# Network configuration:
#
# -------------------------------+------------------------ host
#                                |
#                       ---------+---------
#                       | docker_gwbridge |
#                       ---------+---------
#                                |
# -----+---------------+---------+----+-------------+----- nodered
#      | 80            | 1883, 9001   | 8086        | 3000
# -----+-----   -------+-----   ------+-----   -----+-----
# | nodered |   | mosquitto |   | influxdb |   | grafana |
# -----------   -------------   ------------   -----------
#
# service names can be used as host names within containers
# ---------------------------------------------------------

# config
export REGISTRY_PORT=5000
export REGISTRY=localhost:$REGISTRY_PORT

docker network create --driver overlay nodered

# setup registry service
docker service create --network nodered --replicas 1 --name registry -p $REGISTRY_PORT:5000 registry:latest

# push used images to swarm registry
docker build -t $REGISTRY/peteral/nodered ./nodered
docker push $REGISTRY/peteral/nodered

docker pull eclipse-mosquitto
docker tag  eclipse-mosquitto $REGISTRY/eclipse-mosquitto
docker push $REGISTRY/eclipse-mosquitto

docker pull influxdb
docker tag  influxdb $REGISTRY/influxdb
docker push $REGISTRY/influxdb

docker pull grafana/grafana
docker tag  grafana/grafana $REGISTRY/grafana/grafana
docker push $REGISTRY/grafana/grafana

# create services
docker service create --network nodered --replicas 1 --name nodered   -p 80:1880                  $REGISTRY/peteral/nodered
docker service create --network nodered --replicas 1 --name mosquitto -p 1883:1883 -p 9001:9001   $REGISTRY/eclipse-mosquitto
docker service create --network nodered --replicas 1 --name influxdb  -p 8086:8086                $REGISTRY/influxdb
docker service create --network nodered --replicas 1 --name grafana   -p 3000:3000                $REGISTRY/grafana/grafana

# create influx database testdb
curl -X POST 'http://localhost:8086/query?pretty=true' --data-urlencode "q=create database testdb"

# import grafana data source

# import grafana dashboard
export dashboard=`cat dashboard.json`
export request="{ \"dashboard\": $dashboard, \"overwrite\" : false } "
curl -X POST 'http://admin:admin@localhost:3000/api/dashboards/db' -H "Content-Type: application/json" -d "$request"

# import nodered flows
