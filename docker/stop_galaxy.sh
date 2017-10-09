#!/bin/bash

if ! pgrep "supervisord" > /dev/null
then
    # stop everything
    sudo -E -u galaxy ./run.sh --stop-daemon --log-file=$install_log --pid-file=galaxy_install.pid
    rm 'galaxy_install.log'
    service postgresql stop
fi
