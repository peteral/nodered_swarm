#!/bin/bash

# config
export REGISTRY_PORT=5000
export REGISTRY=localhost:$REGISTRY_PORT

echo "-> create network"
docker network create \
    --driver overlay nodered

echo "-> set up swarm registry"
docker service create \
    --network nodered \
    --replicas 1 \
    --name registry \
    --publish $REGISTRY_PORT:5000 \
    registry:latest

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
docker service create \
    --network nodered \
    --replicas 1 \
    --name nodered \
    --publish 80:1880 \
    --mount source=/mnt/drbd1/nodered,destination=/data \
    $REGISTRY/peteral/nodered

echo "-> create mosquitto service"
docker service create \
    --network nodered \
    --replicas 1 \
    --name mosquitto \
    --publish 1883:1883 \
    --publish 9001:9001 \
    $REGISTRY/eclipse-mosquitto

echo "-> create influxdb service"
docker service create \
    --network nodered \
    --replicas 1 \
    --name influxdb \
    --publish 8086:8086 \
    --mount source=/mnt/drbd1/influxdb,destination=/var/lib/influxdb \
    $REGISTRY/influxdb

echo "-> create grafana service"
docker service create \
    --network nodered \
    --replicas 1 \
    --name grafana \
    --publish 3000:3000 \
    --mount source=/mnt/drbd1/grafana,destination=/var/lib/grafana \
    $REGISTRY/grafana/grafana

echo "-> create database"
curl -X POST \
    'http://localhost:8086/query?pretty=true' \
    --data-urlencode "q=create database testdb"

echo "-> create grafana data source"
export datasource=`cat grafana/datasource.json`
curl -X POST \
    'http://admin:admin@localhost:3000/api/datasources' \
    -H "Content-Type: application/json"  \
    --data-raw "$datasource"

echo "-> create grafana dashboard"
export dashboard=`cat grafana/dashboard.json`
export request="{ \"dashboard\": $dashboard } "
curl -X POST \
    'http://admin:admin@localhost:3000/api/dashboards/db' \
    -H "Content-Type: application/json" \
    --data-raw "$request"

echo "-> import nodered flows"
export flows=`cat nodered/flows.json`
curl -X POST \
    'http://localhost/flows' \
    -H "Content-Type: application/json" \
    --data-raw "$flows"
