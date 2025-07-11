# WMTS-Kacheln seeden

Mit dieser Anleitung und der dazugehörigen Umgebung (_Docker Compose_) können WMTS-Kacheln auf einer lokalen Maschine geseedet und die fertigen Kacheln danach auf das produktive System kopiert werden.
Dadurch fällt die Last nicht auf dem produktiven System an.


## Geodaten lokal bereitstellen

Zunächst muss man entscheiden, wo auf dem lokalen Rechner die Daten abgelegt werden sollen. Dieser Pfad muss in der Umgebungsvariable `GEODATA_PATH` gespeichert und danach das entsprechende Verzeichnis angelegt werden, z.B.:

```sh
export GEODATA_PATH=$HOME/geodata
mkdir $GEODATA_PATH
```

### Rasterdaten

Die benötigten Geodaten kopiert man mit folgenden Befehlen auf die lokale Maschine.
Bei einem Update der Hintergrundkarten sind sie möglicherweise bereits lokal vorhanden; dann kann man diesen Schritt hier überspringen.
```
rsync --delete -a --chmod=D0775,F0664 --info=progress2 ~/shares/sogisgeodata/geodata/ch.swisstopo.lk* $GEODATA_PATH
rsync --delete -a --chmod=D0775,F0664 --info=progress2 ~/shares/sogisgeodata/geodata/ch.swisstopo.swissimage_2024.rgb $GEODATA_PATH
rsync --delete -a --chmod=D0775,F0664 --info=progress2 ~/shares/sogisgeodata/geodata/ch.swisstopo.sentinel_2018 $GEODATA_PATH
```

Falls sich die Maschine ausserhalb des Kantonsnetzwerks befindet, kann man die Daten alternativ mit folgenden Befehlen herunterladen, wobei man aber drauf achten muss, dass man den Server files.geo.so.ch nicht überlastet:
```sh
export PRODUCT=lk10; export VARIANT=farbig_relief
# (usw., Umgebungsvariablen-Kombinationen siehe im übernächsten Abschnitt)
```
```sh
mkdir $GEODATA_PATH/ch.swisstopo.${PRODUCT}.${VARIANT}
wget https://files.geo.so.ch/ch.swisstopo.${PRODUCT}.${VARIANT}/aktuell/ch.swisstopo.${PRODUCT}.${VARIANT}.tif -P $GEODATA_PATH/ch.swisstopo.${PRODUCT}.${VARIANT}
mkdir $GEODATA_PATH/ch.swisstopo.swissimage_2024.rgb
wget https://files.geo.so.ch/ch.swisstopo.swissimage_2024.rgb/aktuell/ch.swisstopo.swissimage_2024.rgb.tif -P $GEODATA_PATH/ch.swisstopo.swissimage_2024.rgb
mkdir $GEODATA_PATH/ch.swisstopo.sentinel_2018
wget https://files.geo.so.ch/ch.swisstopo.sentinel_2018/aktuell/ch.swisstopo.sentinel_2018.tif -P $GEODATA_PATH/ch.swisstopo.sentinel_2018
```

### Hoheitsgrenzen

Die in jedem Fall zusätzlich benötigten Hoheitsgrenzen lädt man mit folgendem Befehl herunter:
```sh
wget https://files.geo.so.ch/ch.so.agi.av.hoheitsgrenzen/aktuell/ch.so.agi.av.hoheitsgrenzen.gpkg.zip -P $GEODATA_PATH/
```
Entpacken:
```sh
unzip $GEODATA_PATH/ch.so.agi.av.hoheitsgrenzen.gpkg.zip -d $GEODATA_PATH/ch.so.agi.av.hoheitsgrenzen
```

### Rasterdaten auf dem WMTS-Extent zuschneiden

Fürs Seeden der WMTS-Kacheln wird ein auf dem COG basierenes VRT mit reduziertem Extent erstellt (nur für die Varianten *farbig_relief* und *grau* bzw. *grau_relief*).
Hierfür jeweils eine der folgenden Umgebungsvariablen-Kombinationen setzen und danach den untenstehenden Befehl ausführen:
```sh
# Swiss Map Raster 10
export PRODUCT=lk10; export VARIANT=farbig_relief
export PRODUCT=lk10; export VARIANT=grau_relief
# Swiss Map Raster 25
export PRODUCT=lk25; export VARIANT=farbig_relief
export PRODUCT=lk25; export VARIANT=grau
# Swiss Map Raster 50
export PRODUCT=lk50; export VARIANT=farbig_relief
export PRODUCT=lk50; export VARIANT=grau
# Swiss Map Raster 100
export PRODUCT=lk100; export VARIANT=farbig_relief
export PRODUCT=lk100; export VARIANT=grau
# Swiss Map Raster 200
export PRODUCT=lk200; export VARIANT=farbig_relief
export PRODUCT=lk200; export VARIANT=grau
# Swiss Map Raster 500
export PRODUCT=lk500; export VARIANT=farbig_relief
export PRODUCT=lk500; export VARIANT=grau
# Swiss Map Raster 1000
export PRODUCT=lk1000; export VARIANT=farbig_relief
export PRODUCT=lk1000; export VARIANT=grau_relief
```
```sh
cd $GEODATA_PATH/ch.swisstopo.${PRODUCT}.${VARIANT}
gdal_translate -of VRT -projwin 2570000 1268000 2667000 1208000 ch.swisstopo.${PRODUCT}.${VARIANT}.tif ch.swisstopo.${PRODUCT}-masked.${VARIANT}.vrt
```


## Kacheln erstellen (seeden)

### Vorbereitung

Git-Repository auschecken und ins `seed`-Unterverzeichnis wechseln:

```sh
git clone https://github.com/sogis/docker-mapcache.git && cd docker-mapcache
cd seed
```

Definieren, wo die Geodaten liegen und wo die Kacheln erstellt werden sollen:

```sh
export GEODATA_PATH=$HOME/geodata
export TILES_PATH=/tmp/tiles
```

Verzeichnis für die Tiles anlegen:

```sh
mkdir $TILES_PATH
```

### Nur bei Bedarf: Änderungen an *.qgs*-Dokumenten vornehmen

Falls Änderungen an den *.qgs*-Dokumenten nötig sein sollten, können kleinere Anpassungen möglicherweise mit einem Skript realisiert werden.
Z.B. für die Änderung eines Orthofoto-Standes:

```sh
sed -i -E 's/swissimage_2021/swissimage_2024/g' qgs/ch.so.agi.hintergrundkarte_ortho.qgs
```
Falls hingegen manuelle Änderungen an *.qgs*-Dokumenten notwendig sind, kann man mit dem folgenden Befehl einen Docker-Container mit der passenden QGIS-Version starten und die Anpassungen dort vornehmen:
```sh
docker run -it --rm --name qgis -u $UID \
-e HOME=/home/$UID -e DISPLAY=$DISPLAY -e GDAL_PAM_ENABLED=NO \
-v /tmp/.X11-unix:/tmp/.X11-unix -v /tmp:/home/$UID \
-v ./qgs:/home/$UID/qgs -v $GEODATA_PATH:/geodata \
qgis/qgis:final-3_28_7 qgis
```

Die Geodaten sind hierbei unter `/geodata` verfügbar.
Zu beachten ist beim Editieren, dass die Pfade zu den Geodaten *absolut* gespeichert sein müssen.
(Der Pfad zu den geladenen Geodaten muss also mit `/geodata` beginnen.)

### Nur bei Bedarf: Änderungen an *.qgs*-Dokumenten mittels Vagrant Box vornehmen (veraltet)

Falls vor dem Seeden hingegen manuelle Änderungen
an *.qgs*-Dokumenten notwendig sind,
macht man dies in der Vagrant-Box
[sogis/ubuntu-qgis-3.16](https://app.vagrantup.com/sogis/boxes/ubuntu-qgis-3.16).
(Weitere Dokumentation zu dieser Vagrant-Box unter
https://github.com/sogis/vagrant-ubuntu-18.04-qgis-3.16#use-box.)

Vagrant-Box initialisieren:

```
vagrant init sogis/ubuntu-qgis-3.16
```

Im Vagrantfile (wurde im aktuellen Verzeichnis angelegt)
folgende Zeilen ergänzen
(wobei der Pfad zu den *.qgs*-Dateien an den Pfad anzupassen ist,
in welchem das *docker-mapcache*-Repo ausgecheckt ist):

```
config.vm.synced_folder "./qgs", "/home/vagrant/qgs"
config.vm.synced_folder ENV['GEODATA_PATH'], "/geodata"

config.ssh.forward_x11 = true
```

Dann startet man die Box mit

```
export GEODATA_PATH=$HOME/geodata
vagrant up
```

QGIS startet man mit dem Befehl

```
vagrant ssh -c qgis
```

Nun können die *.qgs*-Dokumente nach Bedarf editiert werden.
Zu beachten ist, dass die Pfade zu den Geodaten
*absolut* gespeichert sein müssen.
Diese Einstellung ist unter *Project > Properties / General* zu finden.
(Der Pfad zu den geladenen Geodaten muss also mit `/geodata` beginnen.)

### Seeden

Die aktuellsten Docker Images pullen:

```sh
docker compose pull
```

Den WMS starten:

```sh
docker compose up -d wms
```

Seeden:

```sh
# hintergrundkarte_farbig, nur die Landeskarten-Zoomstufen, Daucer ca. 10min:
docker compose run --rm -u $UID -e SOURCE_URL=http://wms/qgis/ch.so.agi.hintergrundkarte_farbig wmts mapcache_seed -c /mapcache/mapcache.xml -t ch.so.agi.hintergrundkarte_farbig -f -z 0,10 -n 4
# hintergrundkarte_sw, nur die Landeskarten-Zoomstufen, Dauer ca. 6min:
docker compose run --rm -u $UID -e SOURCE_URL=http://wms/qgis/ch.so.agi.hintergrundkarte_sw wmts mapcache_seed -c /mapcache/mapcache.xml -t ch.so.agi.hintergrundkarte_sw -f -z 0,10 -n 4
# hintergrundkarte_ortho, alle Zoomstufen:
docker compose run --rm -u $UID -e SOURCE_URL=http://wms/qgis/ch.so.agi.hintergrundkarte_ortho wmts mapcache_seed -c /mapcache/mapcache.xml -t ch.so.agi.hintergrundkarte_ortho -f -z 0,14 -n 4
```
Zur Information:
* Der MapCache-Service ist während des Seedens nicht verfügbar
* QGIS Server ist bei Bedarf unter z.B. der folgenden URL erreichbar:
  http://localhost:8081/qgis/ch.so.agi.hintergrundkarte_sw?SERVICE=WMS&REQUEST=GetCapabilities

Den WMS stoppen:

```sh
docker compose down
```

Um das Resultat zu prüfen den WMTS starten (nach Bedarf):

```sh
docker compose run --rm --service-ports wmts
```
Danach http://localhost:8080/demo/wmts aufrufen **und im Viewer auf den Plus-Button rechts oben klicken und dort den entsprechenden Layer einschalten**.


Falls man noch weitere Änderungen an den *.qgs*-Dokumenten machen muss, muss man vor dem nächsten Seeden ein `docker compose down` und `docker compose up -d wms` ausführen, damit die Änderungen übernommen werden.


## Kacheln in OpenShift publizieren

Zunächst muss der Inhalt des `$TILES_PATH` kurz überprüft werden. Danach meldet man sich an OpenShift an und kopiert mit folgenden Befehlsvorlagen die Kacheln auf einen der *MapCache*-Pods. Danach müssen **alle** *MapCache*-Pods neu gestartet werden, z.B. mit `oc delete pod ...`. Der Neustart ist nötig, damit Dateien, auf die der Service während des Kopierens noch zugegriffen hat, freigegeben werden und dadurch auch tatsächlich gelöscht werden.

```sh
oc rsync --no-perms --progress ${TILES_PATH:-/tmp/tiles}/ mapcache-65-srz54:/tiles
oc delete pod mapcache-65-srz54
oc delete pod mapcache-65-vm8jg
```
