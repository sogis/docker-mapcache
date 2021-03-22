# docker-mapcache

## Build 

```
docker build -t sogis/docker-mapcache:latest .
```

## Run

```
docker run -p 8281:8080 -v /tmp/tiles:/tiles --rm --name mapcache sogis/docker-mapcache:latest
```

The following environment variables may be passed:
```
-e SERVICE_URL=https://geo-t.so.ch/api # The base URL of the MapCache service
-e SOURCE_URL=https://geo-t.so.ch/api/wms # The base URL of the source WMS
-e DEMO_SERVICE_ENABLED=true # Enable the MapCache demo service (a basic map viewer)
```

Log into container:
```
bash -c "clear && docker exec -it mapcache /bin/bash"
```

WMTSCapabilities.xml:
```
http://localhost:8281/mapcache/wmts/1.0.0/WMTSCapabilities.xml
```

Demo map (if enabled):
```
http://localhost:8281/mapcache/demo
```

Troubleshooting:

If MapCache logs messages like
`sqlite backend failed to open db /tiles/xy.db: unable to open database file`,
then it maybe doesn't have write permission on the tiles host directory.
In this case run the following command on the host machine:
```
sudo chmod g+w /tmp/tiles/
```

## Seeding

Please refer to the instructions in the _seed_ folder.
