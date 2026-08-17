#!/bin/bash

# Provides a MapCache config file from a template
# and replaces placeholders with actual values

MOUNTED_CONFIG_FILE_TEMPLATE='/mapcache/mapcache-configfile-template/mapcache.xml.tpl'
DEFAULT_CONFIG_FILE_TEMPLATE='/mapcache/mapcache-configfile-template/mapcache-default.xml.tpl'
CONFIG_FILE='/mapcache/mapcache.xml'

if [[ -f "$MOUNTED_CONFIG_FILE_TEMPLATE" ]]; then
    echo "Copying mounted MapCache config file template found at $MOUNTED_CONFIG_FILE_TEMPLATE to $CONFIG_FILE"
    cp "$MOUNTED_CONFIG_FILE_TEMPLATE" "$CONFIG_FILE"
else
    echo "Copying default MapCache config file template $DEFAULT_CONFIG_FILE_TEMPLATE to $CONFIG_FILE"
    cp "$DEFAULT_CONFIG_FILE_TEMPLATE" "$CONFIG_FILE"
fi

sed -i "s|SOURCE_URL|${SOURCE_URL:-https://geo-t.so.ch/api/wms}|g" ${CONFIG_FILE}
sed -i "s|DEMO_SERVICE_ENABLED|${DEMO_SERVICE_ENABLED:-false}|g" ${CONFIG_FILE}
if [[ -n $SERVICE_URL ]]
then
    sed -i "s|<\!-- \(<url>\)SERVICE_URL\(</url>\) -->|\1${SERVICE_URL}\2|g" ${CONFIG_FILE}
fi


# Run the command defined by CMD in the Dockerfile

exec "$@"
