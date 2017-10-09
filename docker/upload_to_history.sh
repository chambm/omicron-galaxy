#!/bin/bash

if pgrep "supervisord" > /dev/null
then
    export PORT=80
else
    export PORT=8080
fi

history_id=$(su galaxy -c "python scripts/api/history_create_history.py $GALAXY_DEFAULT_ADMIN_KEY http://localhost:$PORT/api/histories \"Test data\" | grep -oP \"(?<='id': u')[^']+\"")
echo Test data history id: $history_id

for file in "$@"; do
    hda_id=$(su galaxy -c "python scripts/api/upload_to_history.py $GALAXY_DEFAULT_ADMIN_KEY http://localhost:$PORT $history_id $file | jq --raw-output .outputs[0].id")
    echo Test HDA id: $hda_id

    # loop while the uploaded HDA state isn't where we want it
    while
      state=$(su galaxy -c "python scripts/api/display.py $GALAXY_DEFAULT_ADMIN_KEY http://localhost:$PORT/api/histories/$history_id/contents/$hda_id | grep -oP \"(?<=state: )\S+\"")
      echo "Waiting for upload: $state"
      [[ $state != "ok" && $state != "error" ]]
    do
      sleep 1
    done

    if [[ $state == "error" ]]
    then
        echo "Error uploading $file"
        exit 1
    fi
done
