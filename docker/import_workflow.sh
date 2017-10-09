#!/bin/bash

if pgrep "supervisord" > /dev/null
then
    export PORT=80
else
    export PORT=8080
fi

for workflow in "$@"; do
    su galaxy -c "python $GALAXY_ROOT/scripts/api/workflow_import_from_file_rpark.py $GALAXY_DEFAULT_ADMIN_KEY http://localhost:$PORT/api/workflows $workflow"
done

exit_code=$?

if [ $exit_code != 0 ] ; then
    exit $exit_code
fi
