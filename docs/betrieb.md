# Betrieb

## Architektur
![MapCache](https://github.com/edigonzales/docker-mapcache/blob/master/docs/mapcache-architektur.png)

Für einen vollautomatischen Seedingprozess innerhalb und mit OpenShift wird zukünftig eine zweite MapCache-Instanz benötigt. Diese wird dann als Kubernetes/OpenShift-Cronjob definiert und übernimmt das Seeden. Falls die Performanz des "SO!MAP-WMS" nicht reicht, kann eine zusätzliche QGIS-Server-Instanz (Docker-Image plusminus vorbereitet) innerhalb von OpenShift gestartet werden. Diese Instanz muss im QGIS-Projektfile (oder -files) nur die Hintergrundkarten (resp. die zu seedenden Karten) definiert haben.

Als Cache wird SQlite (pro Tileset / pro Zoomstufe) verwendet.

## Openshift
Zu definieren ist das Volume für die SQlite-Caches. -> Hat eventuell noch Auswirkungen auf das Dockerfile. MapCache schreibt die SQlite-Datein in das `/tiles`-Verzeichnis, das gemountet werden kann. Lokale Tests haben gezeigt, dass - obwohl das gemountete `/tiles`-Verzeichnis `root` gehört - im Laufenden Betrieb MapCache aus den SQlite-Dateien die Tiles lesen und ausliefern kann. Was wohl nicht geht, ist das Schreiben von allfällig fehlenden, da MapCache als `www-data` läuft (was aber sowieso aus Performancegründen nicht unbedingt unser Ziel ist).

## Docker-Image
Die MapCache-Konfiguration `mapcache.xml` ist hardcodiert im Image und muss bei Änderungen bei den WMS-Endpunkten dementsprechend angepasst werden. Bei Bedarf kann das Dockerfile so angepasst werden, dass die Konfiguration gemountet werden kann.

Die `WMTSCapabilities`-URL ist: `http://localhost:8281/mapcache/wmts/1.0.0/WMTSCapabilities.xml`

Im Image ist eine GeoPackage-Datei mit gebufferten Kantonsgrenzen (1km) für das Seeden des Grundbuchplanes.

## Seeding
Mit nur einer MapCache-Instanz in Openshift muss das Seeding manuell ausgeführt werden indem man sich in den Container einloggt:

```
bash -c "clear && docker exec -it mapcache /bin/bash"
```

(oder OpenShift entsprechend)

### Perimeter
Es gibt zwei Perimeter. Der erste entspricht dem im `mapcache.xml` definierten Extent. Dieser wird verwendet um die statischen Zoomstufen zu seeden (Orthofotos, Landeskarten). Der zweite Perimeter ist eine um einen Kilometer gebufferte Kantonsgrenze. Diese wird zum Seeden des Planes für das Grundbuch verwendent, da ausserhalb des Kantons keine Daten vorhanden sind.

### Tägliches Seeden (to be done)
Die Daten der amtlichen Vermessung werden mindestens einmal pro Woche von verschiedenen Nachführungsgeometern geliefert. Aus diesem Grund müssen die Zoomlevel, wo die Daten der amtlichen Vermessung dargestellt werden und im Perimeter, wo sich die Daten neu geliefert wurden, jeden Tag neu gerechnet werden.

MapCache kann auf eine beliebige OGR-Datenquelle zum Eingrenzen des Seeding-Perimeters zugreifen, z.B. PostgreSQL:


```
-d PG:"dbname='pub' host='192.168.50.6' port='5432' user='user' password='password'" -s "select * from test" 
``` 

Es kann eine View (innerhalb des MOpublic-Schemas) oder mit GRETL ein Tabelle täglich aktualisiert werden, deren Inhalt die neu gelieferten Gemeinden sind. Leider kann man mit MapCache "nur" die OGR-Sql-Syntax verwenden (`-s`) . Dies verunmöglicht das direkte Abfragen der neu gelieferten Gemeinden. 

Die statischen Zoomstufen müssen nicht täglich geseeded werden, nur bei Bedarf (z.B. neues Orthofoto oder aktualisierte Landeskarten).

### Beispiel-Befehle

Orthofoto, Zoomstufen 0 bis 10, 2 Threads, alle Kacheln ersetzen:

`mapcache_seed -c /mapcache/mapcache.xml -t ch.so.agi.hintergrundkarte_ortho -f -z 0,10 -n 2`

Hintergrundkarte farbig, Zoomstufen 11,14, 4 Threads, alle Kacheln ersetzen, Perimeterbeschränkung

`mapcache_seed -c /mapcache/mapcache.xml -t ch.so.agi.hintergrundkarte_farbig -f -z 11,14 -n 4 -d /data/wmts-seeding-perimeter.gpkg -l kanton1000m`




Cronjob
Perimeter -> Sql/gretl/view/

## QWC2-Konfigurationen
