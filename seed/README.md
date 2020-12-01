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

Zudem für die Vektordaten der Amtlichen Vermessung:

```
DBHOST=xy
java -jar ili2pg-4.3.1.jar --export --dbschema agi_mopublic_pub --models SO_AGI_MOpublic_20190424 --dbhost $DBHOST --dbdatabase pub --dbusr $USER --dbpwd $(awk -v dbhost=$DBHOST -F ':' '$1~dbhost{print $5}' ~/.pgpass) --dbparams ~/.ili2pg_dbparams --disableValidation $GEODATA_PATH/agi_mopublic_pub.xtf
```

Danach müssen noch die Schritte, die unter _Importieren der Vektordaten in die lokale DB_ im Abschnitt _Bereitstellen der Geodaten auf einer beliebigen lokalen Maschine_ beschrieben sind, ausgeführt werden, um die Daten in eine lokale DB zu importieren. Dies ist aber nicht nötig, falls man nicht auf einer lokalen Maschine im AGI seeden möchte, sondern die Daten hier nur bereitstellt und schliesslich auf einer beliebigen lokalen Maschine seeden wird.)

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

zip agi_mopublic_pub.xtf.zip agi_mopublic_pub.xtf
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

unzip agi_mopublic_pub.xtf.zip
```

Importieren der Vektordaten in die lokale DB:

```
cd seed
# Der Pfad, wo die Kacheln erstellt werden sollen, muss bereits festgelegt werden, z.B.
export TILES_PATH=/tmp/tiles
docker-compose pull && docker-compose up

java -jar ili2pg-4.3.1.jar \
--dbhost localhost --dbport 54322 --dbdatabase pub --dbusr admin --dbpwd admin \
--schemaimport --dbschema agi_mopublic_pub --models SO_AGI_MOpublic_20190424 \
--defaultSrsCode 2056 --strokeArcs --createGeomIdx --createFk --createFkIdx --createEnumTabs --beautifyEnumDispName --createMetaInfo --createUnique --createNumChecks --nameByTopic

psql -h localhost -p 54322 -d pub -U admin \
-c "GRANT USAGE ON SCHEMA agi_mopublic_pub TO gretl; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA agi_mopublic_pub TO gretl; GRANT USAGE ON ALL SEQUENCES IN SCHEMA agi_mopublic_pub TO gretl;"

java -jar ili2pg-4.3.1.jar \
--dbhost localhost --dbport 54322 --dbdatabase pub --dbusr gretl --dbpwd gretl \
--import --dbschema agi_mopublic_pub --models SO_AGI_MOpublic_20190424 --disableValidation $GEODATA_PATH/agi_mopublic_pub.xtf
```

## Kacheln erstellen (seeden)

### Vorbereitung

Git-Repository auschecken und ins `seed`-Unterverzeichnis wechseln:

```
git clone https://github.com/sogis/docker-mapcache.git && cd docker-mapcache
cd seed
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

Zudem muss die Datei `pg_service.conf` im Home-Verzeichnis abgelegt werden:

```
cp -i pg_service.conf ~/.pg_service.conf
```


Nun können die .qgs-Dokumente im lokalen QGIS nach Bedarf editiert werden. Zu beachten:
* Die Pfade zu den Geodaten müssen absolut gespeichert werden (diese Einstellung ist unter _Project > Properties / General_)
* Die Geodaten müssen über den soeben angelegten symbolischen Link `/geodata` geladen werden
* Es soll die aktuelle QGIS-LTR-Version verwendet werden; idealerweise soll sie mit der in `docker-compose.yml` für QGIS-Server verwendeten Version übereinstimmen

### Seeden

```
docker-compose pull && docker-compose up
```

In einem anderen Terminal ausführen:

```
docker exec -it seed_seeder_1 mapcache_seed -c /mapcache/mapcacheseed.xml -t ch.so.agi.hintergrundkarte_sw -f -z 0,10 -n 4
docker exec -it seed_seeder_1 mapcache_seed -c /mapcache/mapcacheseed.xml -t ch.so.agi.hintergrundkarte_farbig -f -z 0,10 -n 4
docker exec -it seed_seeder_1 mapcache_seed -c /mapcache/mapcacheseed.xml -t ch.so.agi.hintergrundkarte_ortho -f -z 0,14 -n 4
```

Falls man noch weitere Änderungen an den .qgs-Dokumenten machen muss, führt man sicherheitshalber vor dem nächsten `docker-compose up` ein `docker-compose down` aus, damit die Änderungen übernommen werden.

### Kacheln in OpenShift publizieren

Die mit *docker-compose* gestarteten Container stoppen durch Drücken von `Ctrl-C`.

Danach sich an OpenShift anmelden und mit folgenden Befehlsvorlagen die Kacheln auf einen der *MapCache*-Pods kopieren und **alle** *MapCache*-Pods neu starten mit `oc delete pod ...`. Der Neustart ist nötig, damit Dateien, auf die der Service während des Kopierens noch zugegriffen hat, freigegeben werden.

```
oc rsync $TILES_PATH/ docker-mapcache-65-srz54:/tiles --include=ch.so.agi.hintergrundkarte_sw-*
oc rsync $TILES_PATH/ docker-mapcache-65-srz54:/tiles --include=ch.so.agi.hintergrundkarte_farbig-*
oc rsync $TILES_PATH/ docker-mapcache-65-srz54:/tiles --include=ch.so.agi.hintergrundkarte_ortho-*
oc delete pod docker-mapcache-65-srz54
oc delete pod docker-mapcache-65-vm8jg
```

### Information

Wenn die Docker-Container laufen, sind die Dienste unter folgenden URLs erreichbar:
* WMTS: http://localhost:8080/mapcache/wmts/1.0.0/WMTSCapabilities.xml
* WMS: http://localhost:8081/qgis/ch.so.agi.hintergrundkarte_sw?SERVICE=WMS&REQUEST=GetCapabilities
