# Running docker-mapcache in OpenShift

## Set up MapCache

Run the following commands to set up MapCache:
```
oc new-project mapcache
oc new-app sogis/docker-mapcache
oc expose service docker-mapcache --hostname=wmts.example.org
```

Check the deployment:
```
http://wmts.example.org/mapcache/wmts/1.0.0/WMTSCapabilities.xml
```

## Set up MapCache seeder Cron Jobs

Run the following commands to create two OpenShift Cron Jobs which regularly update a part of the MpaCache tiles:
```
git clone https://github.com/sogis/docker-mapcache.git
sed -e 's/color/grayscale/' -e 's/farbig/sw/' openshift/cronjob_seeder_color.yaml > openshift/cronjob_seeder_grayscale.yaml
oc project mapcache
oc create -f openshift/cronjob_seeder_color.yaml
oc create -f openshift/cronjob_seeder_grayscale.yaml
```
(The ```sed``` command generates the template for the second Cron Job, *cronjob_seeder_grayscale.yaml*. So *cronjob_seeder_color.yaml* in a way serves as a master Cron Job template.)

## Run MapCache seeder Jobs that need to run on demand only

Run the following commands to run OpenShift Jobs that update the "static" part of the MapCache tiles:
```
git clone https://github.com/sogis/docker-mapcache.git
sed -e 's/color/grayscale/' -e 's/farbig/sw/' openshift/job_seeder_color_static.yaml > openshift/job_seeder_grayscale_static.yaml
sed -e 's/color/orthophoto/' -e 's/farbig/ortho/' -e 's/0,10/0,14/' openshift/job_seeder_color_static.yaml > openshift/job_seeder_orthophoto_static.yaml
oc project mapcache
oc delete job $(oc get -l job-name=seeder-color-static jobs -o custom-columns=NAME:metadata.name --no-headers) && oc create -f openshift/job_seeder_color_static.yaml
oc delete job $(oc get -l job-name=seeder-grayscale-static jobs -o custom-columns=NAME:metadata.name --no-headers) && oc create -f openshift/job_seeder_grayscale_static.yaml
oc delete job $(oc get -l job-name=seeder-orthophoto-static jobs -o custom-columns=NAME:metadata.name --no-headers) && oc create -f openshift/job_seeder_orthophoto_static.yaml
```
(On the very first run after generating the OpenShift project, the commands to start the jobs are just
```
oc create -f openshift/job_seeder_color_static.yaml
oc create -f openshift/job_seeder_grayscale_static.yaml
oc create -f openshift/job_seeder_orthophoto_static.yaml
```
because there is no existing job to delete yet.)
