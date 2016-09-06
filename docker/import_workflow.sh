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
    
    galaxy_install_pid=`cat galaxy_install.pid`
    
    while : ; do
        tail -n 2 $install_log | grep -E -q "Removing PID file galaxy_install.pid|Daemon is already running"
        if [ $? -eq 0 ] ; then
            echo "Galaxy could not be started."
            echo "More information about this failure may be found in the following log snippet from galaxy_install.log:"
            echo "========================================"
            tail -n 60 $install_log
            echo "========================================"
            echo $1
            exit 1
        fi
        tail -n 2 $install_log | grep -q "Starting server in PID $galaxy_install_pid"
        if [ $? -eq 0 ] ; then
            echo "Galaxy is running."
            break
        fi
    done
fi

for workflow in "$@"; do
    su galaxy -c "python $GALAXY_ROOT/scripts/api/workflow_import.py $GALAXY_DEFAULT_ADMIN_KEY http://localhost:8080 $workflow"
done

exit_code=$?

if [ $exit_code != 0 ] ; then
    exit $exit_code
fi

if ! pgrep "supervisord" > /dev/null
then
    # stop everything
    sudo -E -u galaxy ./run.sh --stop-daemon --log-file=$install_log --pid-file=galaxy_install.pid
    rm $install_log
    service postgresql stop
fi
