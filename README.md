# docker-mapcache

## Build 

```
docker build -t sogis/mapcache:latest .
```

## Run
```
docker run -p 8281:80 -v /tmp:/tiles --rm --name mapcache sogis/docker-mapcache
```

Log into container:
```
bash -c "clear && docker exec -it mapcache /bin/bash"
```

Seeding:
```
docker exec -it mapcache mapcache_seed -c /mapcache/mapcache.xml -t ch.so.agi.hintergrundkarte_farbig -f -z 11,11 -n 4 -d /data/wmts-seeding-geom.gpkg -l kanton1000m
```

WMTSCapabilities.xml:
```
http://localhost:8281/mapcache/wmts/1.0.0/WMTSCapabilities.xml
```


