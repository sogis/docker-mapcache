#!/bin/bash

# Provides a MapCache config file from a template
# and replaces placeholders with actual values

CONFIG_FILE_TEMPLATE='/mapcache/mapcache-template.xml'
CONFIG_FILE='/mapcache/mapcache.xml'

if [[ -e "$CONFIG_FILE_TEMPLATE" ]]; then
    cp "$CONFIG_FILE_TEMPLATE" "$CONFIG_FILE"
fi

sed -i "s|SOURCE_URL|${SOURCE_URL:-https://geo-t.so.ch/api/wms}|g" ${CONFIG_FILE}
sed -i "s|DEMO_SERVICE_ENABLED|${DEMO_SERVICE_ENABLED:-false}|g" ${CONFIG_FILE}
if [[ -n $SERVICE_URL ]]
then
    sed -i "s|<\!-- \(<url>\)SERVICE_URL\(</url>\) -->|\1${SERVICE_URL}\2|g" ${CONFIG_FILE}
fi


# Run the command defined by CMD in the Dockerfile

exec "$@"
