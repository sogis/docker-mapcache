# WMTS-Kacheln seeden

Mit dieser Anleitung und der dazugehörigen Umgebung (_Docker Compose_) können WMTS-Kacheln auf einem anderen System als auf dem produktiven WMTS geseedet werden (z.B. auf der lokalen Maschine). Die fertigen Kacheln müssen danach nur noch auf das produktive System kopiert werden.


## Bereitstellen der Geodaen auf einer lokalen Maschine im AGI

Zunächst muss man entscheiden, wo auf dem lokalen Rechner die Daten abgelegt werden sollen. Dieser Pfad muss in der Umgebungsvariable `GEODATA_PATH` gespeichert und danach das entsprechende Verzeichnis angelegt werden, z.B.:

```
export GEODATA_PATH=$HOME/geodata
mkdir $GEODATA_PATH
```

Die benötigten Geodaten kopiert man mit `scp` hierher bzw. generiert man mit ogr2ogr:

```
scp -rp USERNAME@UTIL-SERVERNAME:/opt/sogis_pic/geodata/ch.swisstopo.lk* $GEODATA_PATH
scp -rp USERNAME@UTIL-SERVERNAME:/opt/sogis_pic/geodata/ch.so.agi.hintergrundkarte $GEODATA_PATH
ogr2ogr -f GPKG -overwrite $GEODATA_PATH/hoheitsgrenzen_kantonsgrenze.gpkg PG:'host=geodb.rootso.org dbname=pub user=xy password=xy' -nln hoheitsgrenzen_kantonsgrenze agi_hoheitsgrenzen_pub.hoheitsgrenzen_kantonsgrenze
scp -rp USERNAME@UTIL-SERVERNAME:/opt/sogis_pic/geodata/ch.swisstopo.swissimage_2018.rgb $GEODATA_PATH
scp -rp USERNAME@UTIL-SERVERNAME:/opt/sogis_pic/geodata/ch.swisstopo.sentinel_2018 $GEODATA_PATH
```

Nun kann man gemäss der Anleitung im Abschnit _Kacheln erstellen (seeden)_ mit dem Seeden starten.


## Bereitstellen der Geodaten auf einer beliebigen lokalen Maschine

Falls man die Kacheln auf einer externen Maschine seeden möchte, muss man zunächst ebenfalls auf der AGI-Maschine die obigen Schritte ausführen, um die Geodaten auf die AGI-Maschine zu kopieren. Danach speichert man sie entweder auf einer externen Festplatte und transferiert sie auf die externe Maschine, wobei auch dort wieder ein `$GEODATA_PATH` angelegt werden muss, wohin man danach die Daten kopiert:

```
export GEODATA_PATH=$HOME/geodata
mkdir $GEODATA_PATH
```

Oder man packt die Daten in ein Archiv und überträgt sie übers Internet. (Die Landeskarten sind allerdings ca. 12GB gross, die Orthofotos 26GB.)

Packen auf der AGI-Maschine:

```
cd $GEODATA_PATH
tar -czf lk.tar.gz ch.swisstopo.lk*
tar -czf maske.tar.gz ch.so.agi.hintergrundkarte/maske.tif
tar -czf ch.swisstopo.swissimage_2018.rgb.tar.gz ch.swisstopo.swissimage_2018.rgb
tar -czf ch.swisstopo.sentinel_2018.tar.gz ch.swisstopo.sentinel_2018
```
(`hoheitsgrenzen_kantonsgrenze.gpkg` muss nicht gepackt werden, und `ch.swisstopo.sentinel_2018` packen wir nur deshalb, weil beim Entpacken praktischerweise auch der richtige Unterordner angelegt wird.)

Entpacken auf der externen Maschine:

```
export GEODATA_PATH=$HOME/geodata
mkdir $GEODATA_PATH
cd $GEODATA_PATH
tar -xzf lk.tar.gz
tar -xzf maske.tar.gz
tar -xzf ch.swisstopo.swissimage_2018.rgb.tar.gz
tar -xzf ch.swisstopo.sentinel_2018.tar.gz
```


## Kacheln erstellen (seeden)

### Vorbereitung

Git-Repository auschecken und ins `seed`-Unterverzeichnis wechseln:

```
git clone https://github.com/sogis/docker-mapcache.git
cd docker-mapcache/seed
```

Definieren, wo die Geodaten liegen und wo die Kacheln erstellt werden sollen:

```
export GEODATA_PATH=$HOME/geodata
export TILES_PATH=/tmp/tiles
```

Verzeichnis für die Tiles anlegen und benötigte Berechtigungen setzen:

```
mkdir $TILES_PATH && sudo chown 1001 $TILES_PATH
```

### Bei Bedarf: Änderungen an .qgs-Dokumenten vornehmen

Falls vor dem Seeden Änderungen an .qgs-Dokumenten notwendig sind, muss zunächst folgender symbolischer Link angelegt werden:

```
export GEODATA_PATH=$HOME/geodata
sudo ln -s -n -f $GEODATA_PATH /geodata
```

Nun können die .qgs-Dokumente im lokalen QGIS nach Bedarf editiert werden. Zu beachten:
* Die Pfade zu den Geodaten müssen absolut gespeichert werden (diese Einstellung ist unter _Project > Properties / General_)
* Die Geodaten müssen über den soeben angelegten symbolischen Link `/geodata` geladen werden
* Es soll die aktuelle QGIS-LTR-Version verwendet werden; idealerweise soll sie mit der in `docker-compose.yml` für QGIS-Server verwendeten Version übereinstimmen

### Seeden

```
docker-compose up
```

In einem anderen Terminal ausführen:

```
docker exec -it seed_seeder_1 mapcache_seed -c /mapcache/mapcacheseed.xml -t ch.so.agi.hintergrundkarte_sw -f -z 0,10 -n 4
docker exec -it seed_seeder_1 mapcache_seed -c /mapcache/mapcacheseed.xml -t ch.so.agi.hintergrundkarte_farbig -f -z 0,10 -n 4
```

Falls man noch weitere Änderungen an den .qgs-Dokumenten machen muss, führt man sicherheitshalber vor dem nächsten `docker-compose up` ein `docker-compose down` aus, damit die Änderungen übernommen werden.

### Information

Wenn die Docker-Container laufen, sind die Dienste unter folgenden URLs erreichbar:
* WMTS: http://localhost:8080/mapcache/wmts/1.0.0/WMTSCapabilities.xml
* WMS: http://localhost:8081/qgis/ch.so.agi.hintergrundkarte_sw?SERVICE=WMS&REQUEST=GetCapabilities
