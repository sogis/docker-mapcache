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



# Function for graceful Apache stop
function stop_apache() {
    echo "Stopping Apache"
    apache2ctl graceful-stop
}

# Run container command
if [ "$1" = 'apache2ctl' ]; then
    # Trap the following signals and execute the stop_apache function when receiving one of them
    trap stop_apache SIGHUP SIGINT SIGTERM

    echo "Starting Apache"
    # Start Apache using apache2ctl as defined in the Dockerfile CMD,
    # and put it in background so the entrypoint script can receive signals
    # (We want to run Apache in the foreground mode (-D FOREGROUND) so it can pipe its output to stdout,
    # but we put apache2ctl in the background here so the entrypoint script can continue and then wait)
    "$@" &
    apache2ctl_pid=$!
    # Wait for state change of the apache2ctl process,
    # which happens after stop_apache function has been called due to a trapped signal
    wait "$apache2ctl_pid"
    exit $?
else
    echo "Running command passed to container"
    exec "$@"
fi
