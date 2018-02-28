#!/bin/bash
# ---------------------------------------------------------
# prerequisites - initialized swarm
# ---------------------------------------------------------

# config
export REGISTRY_PORT=5000
export REGISTRY=localhost:$REGISTRY_PORT

# setup registry service
docker service create --replicas 1 --name registry -p $REGISTRY_PORT:5000 registry:latest

# push used images to swarm registry
docker build -t $REGISTRY/peteral/nodered:latest ./nodered

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
docker service create --replicas 1 --name nodered   -p 80:1880                  $REGISTRY/peteral/nodered
docker service create --replicas 1 --name mosquitto -p 1883:1883 -p 9001:9001   $REGISTRY/eclipse-mosquitto
docker service create --replicas 1 --name influxdb  -p 8086:8086                $REGISTRY/influxdb
docker service create --replicas 1 --name grafana   -p 3000:3000                $REGISTRY/grafana/grafana

# create influx database testdb
curl -X POST 'http://localhost:8086/db?u=root&p=root' -d '{"name" : "testdb"}'

# import grafana dashboard
export dashboard='{ "dashboard": {' `cat dashboard.json` ' }, "overwrite" : false } '
curl -X POST 'http://localhost:3000/api/dashboards/db' -H "Content-Type: application/json" -d $dashboard

# import nodered flows