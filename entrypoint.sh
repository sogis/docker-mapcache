#!/usr/bin/env bash
set -euo pipefail


# Set up MapCache configfile
/mapcache/setup-configfile.sh


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
