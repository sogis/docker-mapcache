# Running docker-mapcache in OpenShift

## Set up MapCache

Run the following commands to set up MapCache:
```
oc new-project mapcache
oc new-app sogis/docker-mapcache
oc expose service docker-mapcache --hostname=geo-wmts-t.so.ch
oc set volume dc/docker-mapcache --remove --name=docker-mapcache-volume-1
oc set volume dc/docker-mapcache --add -t pvc --claim-name=gditest-mapcache --mount-path=/tiles --name docker-mapcache-tiles # adapt claim-name to your needs; it must exist already
oc set env dc/docker-mapcache ENVIRONMENT=test
oc scale --replicas=2 dc/docker-mapcache
# if you wish:
oc tag --source=docker sogis/docker-mapcache:latest docker-mapcache:latest --scheduled=true
```

Check the deployment:
```
http://geo-wmts-t.so.ch/mapcache/wmts/1.0.0/WMTSCapabilities.xml
```


## Set up MapCache seeder Cron Job

Run the following commands to create an OpenShift Cron Job which regularly updates a part of the MapCache tiles:
```
git clone https://github.com/sogis/docker-mapcache.git
oc project mapcache
oc process -f docker-mapcache/openshift/seeder-cronjob-template.yaml \
  -p PVC_NAME=gditest-mapcache \
  -p ZOOM_LEVELS=11,14 \
  -p SCHEDULE='00 04 * * *' \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
```

## For the seeder Jobs we use a separate QGIS-Server Pod

Run the following commands to create the QGIS Server Pod
```
git clone https://github.com/sogis/docker-mapcache.git
oc project agi-mapcache-test
oc process -f docker-mapacache/openshift/seeder-qgis-server.yaml \
  -p NAMESPACE=agi-mapcache-test \
  -p DB_SERVER=geodb-t.rootso.org \
  -p PW_OGC_SERVER=qR6r4KduYNV7R5u4YOME \
  | oc create -f -
```

## Run MapCache seeder Jobs that need to run on demand only

Run the following commands to directly run OpenShift Jobs that update the "static" part of the MapCache tiles:
```
git clone https://github.com/sogis/docker-mapcache.git
oc project mapcache
oc delete $(oc get -l job-name=seeder-static-farbig job -o name) && \
oc process -f docker-mapcache/openshift/seeder-job-template.yaml \
  -p PVC_NAME=gditest-mapcache \
  -p VARIANT=farbig \
  -p ZOOM_LEVELS=0,10 \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
oc delete $(oc get -l job-name=seeder-static-sw job -o name) && \
oc process -f docker-mapcache/openshift/seeder-job-template.yaml \
  -p PVC_NAME=gditest-mapcache \
  -p VARIANT=sw \
  -p ZOOM_LEVELS=0,10 \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
oc delete $(oc get -l job-name=seeder-static-ortho job -o name) && \
oc process -f docker-mapcache/openshift/seeder-job-template.yaml \
  -p PVC_NAME=gditest-mapcache \
  -p VARIANT=ortho \
  -p ZOOM_LEVELS=0,14 \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
```

(On the very first run after generating the OpenShift project, just run the `oc process ...` commands and omit the `oc delete ...` commands, as there are no existing jobs to delete yet.)
