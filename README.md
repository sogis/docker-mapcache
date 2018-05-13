# docker-mapcache

```
docker build -t sogis/mapcache:latest .
```
```
docker run -p 8281:80 -v /tmp:/var/sig/tiles -v /Users/stefan/Projekte/docker-mapcache:/mapcache --name mapcache sogis/mapcache
```

docker run -p 8281:80 -v /tmp:/var/sig/tiles -v /Users/stefan/Projekte/docker-mapcache/mapcache.xml:/mapcache/mapcache.xml --name mapcache sogis/mapcache

http://localhost:8281/?SERVICE=WMS&REQUEST=GetCapabilities ??

http://localhost:8281/mapcache/wmts?service=wmts&request=getcapabilities&version=1.0.0
http://localhost:8281/mapcache/wmts/1.0.0/WMTSCapabilities.xml