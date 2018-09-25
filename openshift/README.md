# Running docker-mapcache in OpenShift

## Set up MapCache

Run the following commands to set up MapCache:
```
oc new-project mapcache
oc new-app sogis/docker-mapcache
oc expose service docker-mapcache --hostname=wmts.example.org
oc set volume dc/docker-mapcache --remove --name=docker-mapcache-volume-1
oc set volume dc/docker-mapcache --add -t pvc --claim-name=my-storage-claim --mount-path=/tiles --name docker-mapcache-tiles # adapt claim-name to your needs; it must exist already
# if you wish:
oc tag --source=docker sogis/docker-mapcache:latest docker-mapcache:latest --scheduled=true
```

Check the deployment:
```
http://wmts.example.org/mapcache/wmts/1.0.0/WMTSCapabilities.xml
```


## Set up MapCache seeder Cron Jobs

Run the following commands to create two OpenShift Cron Jobs which regularly update a part of the MapCache tiles:
```
git clone https://github.com/sogis/docker-mapcache.git
cd docker-mapcache
oc project mapcache
oc process -f openshift/seeder-cronjob-template.yaml \
  -p PVC_NAME=my-storage-claim \
  -p VARIANT=farbig \
  -p ZOOM_LEVELS=11,14 \
  | oc create -f -
oc process -f openshift/seeder-cronjob-template.yaml \
  -p PVC_NAME=my-storage-claim \
  -p VARIANT=sw \
  -p ZOOM_LEVELS=11,14 \
  | oc create -f -
```


## Run MapCache seeder Jobs that need to run on demand only

Run the following commands to directly run OpenShift Jobs that update the "static" part of the MapCache tiles:
```
oc project mapcache
oc delete $(oc get -l job-name=seeder-static-farbig job -o name) && \
oc process -f openshift/seeder-job-template.yaml \
  -p PVC_NAME=my-storage-claim \
  -p VARIANT=farbig \
  -p ZOOM_LEVELS=0,10 \
  | oc create -f -
oc delete $(oc get -l job-name=seeder-static-sw job -o name) && \
oc process -f openshift/seeder-job-template.yaml \
  -p PVC_NAME=my-storage-claim \
  -p VARIANT=sw \
  -p ZOOM_LEVELS=0,10 \
  | oc create -f -
oc delete $(oc get -l job-name=seeder-static-ortho job -o name) && \
oc process -f openshift/seeder-job-template.yaml \
  -p PVC_NAME=my-storage-claim \
  -p VARIANT=ortho \
  -p ZOOM_LEVELS=0,14 \
  | oc create -f -
```

(On the very first run after generating the OpenShift project, just run the `oc process ...` commands and omit the `oc delete ...` commands, as there are no existing jobs to delete yet.)