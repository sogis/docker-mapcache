# Running docker-mapcache in OpenShift

## Set up MapCache

Run the following commands to set up MapCache:
```
oc new-project mapcache-test
oc new-app sogis/docker-mapcache
oc expose service docker-mapcache --hostname=geo-wmts-t.so.ch
oc set volume dc/docker-mapcache --remove --name=docker-mapcache-volume-1
oc set volume dc/docker-mapcache --add -t pvc --claim-name=gditest-mapcache-lowback --mount-path=/tiles --name docker-mapcache-tiles # adapt claim-name to your needs; it must exist already
oc set env dc/docker-mapcache ENVIRONMENT=test
oc set resources dc docker-mapcache --requests=cpu=10m,memory=200Mi --limits=cpu=50m,memory=600Mi
oc create secret docker-registry sogis-pull-secret --docker-username=xx --docker-password=yy
oc secrets link default sogis-pull-secret --for=pull
oc scale --replicas=2 dc/docker-mapcache
# if you wish:
oc tag --source=docker sogis/docker-mapcache:latest docker-mapcache:latest --scheduled=true
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
  -p TAG=2.0.13 \
  -p REPLICAS=1 \
  -p CPU_REQUEST=1 \
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

Run the following commands to directly run OpenShift Jobs that update the "static" part of the MapCache tiles:
```
git clone https://github.com/sogis/docker-mapcache.git && cd docker-mapcache
oc project mapcache-test
oc delete $(oc get -l job-name=seeder-static-farbig job -o name) && \
oc process -f openshift/seeder-job-template.yaml \
  -p PVC_NAME=gditest-mapcache-lowback \
  -p VARIANT=farbig \
  -p ZOOM_LEVELS=0,10 \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
oc delete $(oc get -l job-name=seeder-static-sw job -o name) && \
oc process -f openshift/seeder-job-template.yaml \
  -p PVC_NAME=gditest-mapcache-lowback \
  -p VARIANT=sw \
  -p ZOOM_LEVELS=0,10 \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
oc delete $(oc get -l job-name=seeder-static-ortho job -o name) && \
oc process -f openshift/seeder-job-template.yaml \
  -p PVC_NAME=gditest-mapcache-lowback \
  -p VARIANT=ortho \
  -p ZOOM_LEVELS=0,14 \
  -p ENVIRONMENT_NAME=test \
  | oc create -f -
```

(On the very first run after generating the OpenShift project, just run the `oc process ...` commands and omit the `oc delete ...` commands, as there are no existing jobs to delete yet.)
