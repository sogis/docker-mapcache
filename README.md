# docker-mapcache

## Build 

```
docker build -t sogis/mapcache:latest .
```

## Run
```
docker run --e ENVIRONMENT='' -p 8281:8080 -v /tmp:/tiles --rm --name mapcache sogis/mapcache
```

Log into container:
```
bash -c "clear && docker exec -it mapcache /bin/bash"
```

Seeding:
```
docker exec -it mapcache mapcache_seed -c /mapcache/mapcache.xml -t ch.so.agi.hintergrundkarte_farbig -f -z 11,11 -n 4 -d /mapcache/wmts-seeding-perimeter.gpkg -l kanton1000m
```

WMTSCapabilities.xml:
```
http://localhost:8281/mapcache/wmts/1.0.0/WMTSCapabilities.xml
```

## Run in OpenShift

See the *openshift* folder for documentation on running *docker-mapcache* in OpenShift and on creating OpenShift Cron Jobs for tile seeding.
