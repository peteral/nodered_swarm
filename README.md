# nodered

Start:
```docker-compose up```

Access:
```
http://localhost
```

Access mosquitto from nodered:
```
nodered_mosquitto_1:1883
```

Create influxdb database:
```
POST /query HTTP/1.1
Host: gigby-v01:8086
Content-Type: application/x-www-form-urlencoded

q=CREATE+DATABASE+testdb
```

Query influxdb data:
```
POST /query?pretty=true HTTP/1.1
Host: gigby-v01:8086
Content-Type: application/x-www-form-urlencoded

q=select+*+from+sensor1&db=testdb
```

Test flows located in [flows.json](../master/flows.json)
