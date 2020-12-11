# Running docker-mapcache in OpenShift

## Set up MapCache

A persistent volume claim for storing the tiles must exist already.

Optional: Specify Docker Hub credentials to use for pulling image:
```
oc project agi-mapcache-test
oc create secret docker-registry sogis-pull-secret --docker-username=xx --docker-password=yy
oc secrets link default sogis-pull-secret --for=pull
```

Deploy MapCache and create service and route:
```
oc project agi-mapcache-test
oc process -f openshift/mapcache_template.yaml \
  -p TAG=latest \
  -p IMPORT_POLICY_SCHEDULED=true \
  -p REPLICA_COUNT=1 \
  -p ENVIRONMENT=test \
  -p TILES_PVC_NAME=gditest-mapcache-lowback \
  -p HOSTNAME=geo-wmts-t.so.ch \
  -p CPU_REQUEST=250m \
  -p CPU_LIMIT=1 \
  -p MEMORY_REQUEST=200Mi \
  -p MEMORY_LIMIT=600Mi \
  | oc apply -f -
```

Check the deployment:
```
http://geo-wmts-t.so.ch/mapcache/wmts/1.0.0/WMTSCapabilities.xml
```

## Set up a separate QGIS Server for seeding

Run the following commands to create a QGIS Server Deployment Configuration; the templates are based on those in https://github.com/sogis/pipelines/tree/master/api_webgisclient/qgis-server, and they are additionally modified so that they use the Image Registry of a different OpenShift project:
```
git clone https://github.com/sogis/docker-mapcache.git && cd docker-mapcache
oc project agi-mapcache-test
oc policy add-role-to-user system:image-puller system:serviceaccount:agi-mapcache-test:default --rolebinding-name puller-agi-mapcache-test -n gdi-test
# Command to use for production environment:
# oc policy add-role-to-user system:image-puller system:serviceaccount:agi-mapcache-production:default --rolebinding-name puller-agi-mapcache-production -n gdi
oc process -f openshift/qgis-server_resources.yaml \
  -p DB_SERVER=xy \
  -p DB_PUB=xy \
  -p USER_OGC_SERVER=xy \
  -p PW_OGC_SERVER=xy \
  | oc apply -f -
oc process -f openshift/qgis-server_deploymentconfig.yaml \
  -p ENVIRONMENT=test \
  -p NAMESPACE=gdi-test \
  -p TAG=latest \
  -p REPLICAS=1 \
  -p CPU_REQUEST=0.5 \
  -p CPU_LIMIT=2 \
  -p MEMORY_REQUEST=2Gi \
  -p MEMORY_LIMIT=4Gi \
  | oc apply -f -
```

## Set up MapCache seeder Cron Job

Run the following commands to create an OpenShift Cron Job which regularly updates a part of the MapCache tiles:
```
git clone https://github.com/sogis/docker-mapcache.git && cd docker-mapcache
oc project mapcache-test
oc process -f openshift/seeder-cronjob-template.yaml \
  -p PVC_NAME=gditest-mapcache-lowback \
  -p ZOOM_LEVELS=11,14 \
  -p SCHEDULE='00 03 * * *' \
  -p ENVIRONMENT_NAME=test \
  -p PGHOST=geodb-t.rootso.org \
  -p PGDATABASE=pub \
  -p PGUSER=ogc_server \
  -p PGPASSWORD=xy \
  | oc apply -f -
```

## Run MapCache seeder Jobs that need to run on demand only

The *hintergrundkarte_ortho* tile set and the zoom levels 0 to 10 of the *ch.so.agi.hintergrundkarte_farbig* and the *ch.so.agi.hintergrundkarte_sw* tile set should be seeded on a local machine. Please refer to the instructions in the *seed* folder.

For manual seeding of the zoom levels 11 to 14 of the *ch.so.agi.hintergrundkarte_farbig* and *ch.so.agi.hintergrundkarte_sw* tile sets, use the following commands:
```
git clone https://github.com/sogis/docker-mapcache.git && cd docker-mapcache
oc project mapcache-test
oc process -f openshift/seeder-job-template.yaml \
  -p PVC_NAME=gditest-mapcache-lowback \
  -p VARIANT=farbig \
  -p ZOOM_LEVELS=11,14 \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
oc process -f openshift/seeder-job-template.yaml \
  -p PVC_NAME=gditest-mapcache-lowback \
  -p VARIANT=sw \
  -p ZOOM_LEVELS=11,14 \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
```
(If any of these jobs already exists, you might need to delete it using the command `oc delete job JOB-NAME`.)
