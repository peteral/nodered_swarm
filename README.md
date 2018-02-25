# nodered test

Architecture:
* First Node Red Flow generates random sensor data and publishes them to MQTT topic **sensor1** on MQTT broker ecplise mosquitto.
* Second Node Red Flow subscribes to the **sensor1** topic on mosquitto und pushes the data as **sensor1** measurement to influxdb database called **testdb**
* Grafana dashboard shows the sensor data from influxdb

## how to run
Note - replace **docker-host** with the name of your docker host machine.

Start:
```
docker-compose up
```
Create influxdb database:
```
POST /query HTTP/1.1
Host: docker-host:8086
Content-Type: application/x-www-form-urlencoded

q=CREATE+DATABASE+testdb
```

Access:
* NodeRed: [http://docker-host]
* Grafana: [http://docker-host:3000]

## additional infos
Access mosquitto from nodered:
```
nodered_mosquitto_1:1883
```

Test flows located in [flows.json](../master/flows.json)
