#!/bin/bash
# ---------------------------------------------------------
# prerequisites - initialized swarm
# docker swarm init
# ---------------------------------------------------------
# Network configuration:
#
# -------------------------------+------------------------ host
#                                |
# ------------          ---------+---------
# | registry |          | docker_gwbridge |
# -----+------          ---------+---------
#      | 5000                    |
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

echo "-> create network"
docker network create --driver overlay nodered

echo "-> set up swarm registry"
docker service create --network nodered --replicas 1 --name registry -p $REGISTRY_PORT:5000 registry:latest

# push used images to swarm registry
echo "-> deploy nodered image"
docker build -t $REGISTRY/peteral/nodered ./nodered
docker push $REGISTRY/peteral/nodered

echo "-> deploy mosquitto image"
docker pull eclipse-mosquitto
docker tag  eclipse-mosquitto $REGISTRY/eclipse-mosquitto
docker push $REGISTRY/eclipse-mosquitto

echo "-> deploy influxdb image"
docker pull influxdb
docker tag  influxdb $REGISTRY/influxdb
docker push $REGISTRY/influxdb

echo "-> deploy grafana image"
docker pull grafana/grafana
docker tag  grafana/grafana $REGISTRY/grafana/grafana
docker push $REGISTRY/grafana/grafana

echo "-> create nodered service"
docker service create --network nodered --replicas 1 --name nodered   -p 80:1880                  $REGISTRY/peteral/nodered
echo "-> create mosquitto service"
docker service create --network nodered --replicas 1 --name mosquitto -p 1883:1883 -p 9001:9001   $REGISTRY/eclipse-mosquitto
echo "-> create influxdb service"
docker service create --network nodered --replicas 1 --name influxdb  -p 8086:8086                $REGISTRY/influxdb
echo "-> create grafana service"
docker service create --network nodered --replicas 1 --name grafana   -p 3000:3000                $REGISTRY/grafana/grafana

echo "-> create database"
curl -X POST 'http://localhost:8086/query?pretty=true' --data-urlencode "q=create database testdb"

echo "-> create grafana data source"
export datasource=`cat grafana/datasource.json`
curl -X POST 'http://admin:admin@localhost:3000/api/datasources' -H "Content-Type: application/json" -d "$datasource"

echo "-> create grafana dashboard"
export dashboard=`cat grafana/dashboard.json`

export request="{ \"dashboard\": $dashboard } "
curl -X POST 'http://admin:admin@localhost:3000/api/dashboards/db' -H "Content-Type: application/json" -d "$request"

echo "-> import nodered flows"
export flows=`cat nodered/flows.json`
curl -X POST 'http://localhost/flows' -H "Content-Type: application/json" -d "$flows"
