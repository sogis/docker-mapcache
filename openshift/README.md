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
sed -e 's/color/grayscale/' -e 's/farbig/sw/' cronjob_seeder_color.yaml > cronjob_seeder_grayscale.yaml
oc project mapcache
oc create -f openshift/cronjob_seeder_color.yaml
oc create -f openshift/cronjob_seeder_grayscale.yaml
```
(The ```sed``` command generates the template for the second Cron Job, *cronjob_seeder_grayscale.yaml*. So *cronjob_seeder_color.yaml* in a way serves as a master Cron Job template.)