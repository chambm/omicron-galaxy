#!/bin/bash

if pgrep "supervisord" > /dev/null
then
    echo "System is up and running. Starting with the installation."
    export PORT=80
else
    # start Galaxy
    export PORT=8080
    service postgresql start
    install_log='galaxy_install.log'
    
    # wait for database to finish starting up
    STATUS=$(psql 2>&1)
    while [[ ${STATUS} =~ "starting up" ]]
    do
      echo "waiting for database: $STATUS"
      STATUS=$(psql 2>&1)
      sleep 1
    done
    
    echo "starting Galaxy"
    sudo -E -u galaxy ./run.sh --daemon --log-file=$install_log --pid-file=galaxy_install.pid

    end=$((SECONDS+60))
    while : ; do
        tail -n 2 $install_log | grep -E -q "Removing PID file galaxy_install.pid|Daemon is already running"
        if [ $? -eq 0 ] || [ $SECONDS -ge $end ] ; then
            echo "Galaxy could not be started."
            echo "More information about this failure may be found in the following log snippet from galaxy_install.log:"
            echo "========================================"
            tail -n 60 $install_log
            echo "========================================"
            echo $1
            exit 1
        fi
        tail -n 2 $install_log | grep -q "Starting server in PID"
        if [ $? -eq 0 ] ; then
            echo "Galaxy is running."
            break
        fi
    done
fi