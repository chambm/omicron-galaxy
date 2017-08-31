#!/bin/bash

# Parse input datasets from tool_script.sh and run them through cat to fully cache them in the NFS FS-Cache
grep -oP "/export/galaxy-central/database/files/\d+/(dataset_\d+\.dat)" ../tool_script.sh | xargs -n 1 -I{} cat {} > /dev/null

# The old way:
# Parse input datasets from tool_script.sh
# Copy input datasets to local storage /tmp
# Replace tool_script.sh references to input datasets with local paths
# Replace tool_script.sh references to output dataset with local path
# Add line to tool_script.sh to copy local output dataset to original output path
