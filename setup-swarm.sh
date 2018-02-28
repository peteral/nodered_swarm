#!/bin/sh
# config
export REGISTRY_PORT=5000
export REGISTRY=localhost:$REGISTRY_PORT

# init swarm
docker swarm init

# setup registry service
docker service create --replicas 1 --name registry -p $REGISTRY_PORT:5000 registry:latest

# push used images to swarm registry
docker build -t $REGISTRY/peteral/nodered:latest ./nodered

docker pull eclipse-mosquitto
docker tag eclipse-mosquitto $REGISTRY/eclipse-mosquitto
docker push $REGISTRY/eclipse-mosquitto

docker pull influxdb
docker tag influxdb $REGISTRY/influxdb
docker push $REGISTRY/influxdb

docker pull grafana/grafana
docker tag grafana/grafana $REGISTRY/grafana/grafana
docker push $REGISTRY/grafana/grafana

# create services
docker service create --replicas 1 --name nodered_nodered_1 -p 80:1880 $REGISTRY/peteral/nodered
docker service create --replicas 1 --name nodered_mosquitto_1 -p 1883:1883 -p 9001:9001 $REGISTRY/eclipse-mosquitto
docker service create --replicas 1 --name nodered_influxfb_1 -p 8086:8086 $REGISTRY/influxdb
docker service create --replicas 1 --name nodered_grafana_1 -p 3000:3000 $REGISTRY/grafana/grafana
