#!/bin/bash
#set -e
. /opt/cfncluster/cfnconfig

if [ "$cfn_node_type" == "MasterServer" ]; then
  echo Master

  #echo manual | sudo tee /etc/init.d/httpd.override
  chkconfig --level 2345 httpd off
  service httpd stop

  yum install docker -y
  service docker start
  gpasswd -a ec2-user docker
  useradd -u 1450 galaxy
  #ln -s /export/galaxy-central /galaxy-central
  #ln -s /export/shed_tools /shed_tools

  # --privileged required for autofs/cvmfs to work
  docker run --name omicron -d --restart=on-failure:10 --net=host --privileged \
    -v /export/:/export/ \
    -v /opt/slurm/:/opt/slurm/ \
    -v /etc/munge:/etc/munge \
    -e "NONUSE=reports,slurmd,slurmctld,condor" \
    -e GALAXY_CONFIG_FTP_UPLOAD_SITE=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) \
    -e GALAXY_CONFIG_CLEANUP_JOB=onsuccess \
    chambm/omicron-cfncluster:release_18.09

  while
    echo "Waiting for Galaxy to start"
    [[ $(docker exec omicron supervisorctl status galaxy:galaxy_web | grep -o RUNNING) != "RUNNING" ]]
  do
    sleep 1
  done
  
  # Copy slurm_prolog.sh script to shared path and edit slurm.conf to use the prolog for fully caching input files on compute nodes
  docker cp omicron:/usr/bin/slurm_prolog.sh /export
  chmod a=rx /export/slurm_prolog.sh
  sed -i.bak "s:#Prolog=:Prolog=/export/slurm_prolog.sh:" /opt/slurm/etc/slurm.conf
  
  # Set jobs to expire after a day
  sed -i.bak "s/MinJobAge=300/MinJobAge=86400/" /opt/slurm/etc/slurm.conf

  # Edit user and group permissions in the docker container to match cfncluster
  container_munge_id=$(docker exec omicron id -u munge)
  docker exec omicron find / -uid $container_munge_id -exec chown -h $(id -u munge) {} + || true
  docker exec omicron usermod -u $(id -u munge) munge
  docker exec omicron usermod -u $(id -u slurm) slurm
  docker exec omicron service munge start

  # Copy omicron-data CVMFS config files to shared path for compute nodes
  docker cp omicron:/etc/cvmfs/keys/omicron-data.duckdns.org.pub /export
  docker cp omicron:/etc/cvmfs/config.d/omicron-data.duckdns.org.conf /export
  docker cp omicron:/etc/cvmfs/default.local /export
fi

if [ "$cfn_node_type" == "ComputeFleet" ]; then
  echo Compute

  useradd -u 1450 galaxy
  ln -s /export/galaxy-central /galaxy-central
  ln -s /export/shed_tools /shed_tools

  mkdir /galaxy_venv
  wget https://raw.githubusercontent.com/chambm/omicron-galaxy/update_18.09/cfncluster/requirements.txt -O /galaxy_venv/requirements.txt && \
  chown -R $(id -u slurm):$(id -g slurm) /galaxy_venv && \
  virtualenv /galaxy_venv && \
  . /galaxy_venv/bin/activate && \
  pip install --upgrade pip && \
  pip install galaxy-lib && \
  pip install -r /galaxy_venv/requirements.txt --index-url https://wheels.galaxyproject.org/simple && \
  deactivate

  yum install -y docker
  service docker start
  echo "galaxy  ALL = (root) NOPASSWD: SETENV: /usr/bin/docker" >> /etc/sudoers

  # Download galaxy-extras role for CVMFS task
  pip install ansible
  ansible-galaxy install --roles-path ~/roles git+https://github.com/galaxyproject/ansible-galaxy-extras.git,6ba80a218c1c7004c8d435c4b5a96b6235d53089

  # Create one-task playbook
  cat <<EOF > cvmfs.yml
- hosts: localhost
  tasks:
    - name: Setup CVMFS for compute node
      include_role:
        name: ~/roles/ansible-galaxy-extras
        tasks_from: cvmfs_client.yml
EOF

  # Tweak CVMFS task to use yum
  sed -E -i.bak 's/apt: [^=]+=/yum: name=/' ~/roles/ansible-galaxy-extras/tasks/cvmfs_client.yml
  sed -i.bak 's/\.deb/.rpm/' ~/roles/ansible-galaxy-extras/tasks/cvmfs_client.yml
  CVMFS_RPM="http://cvmrepo.web.cern.ch/cvmrepo/yum/cvmfs/EL/5/x86_64/cvmfs-2.1.20-1.el5.x86_64.rpm"
  CVMFS_CONFIG_RPM="http://cvmrepo.web.cern.ch/cvmrepo/yum/cvmfs/EL/6/x86_64/cvmfs-config-default-1.2-2.noarch.rpm"

  # Download and install CVMFS
  ansible-playbook -e "galaxy_extras_install_packages=true galaxy_tool_data_table_config_file=/tmp/compute-notused cvmfs_deb_url=$CVMFS_RPM cvmfs_deb_config_url=$CVMFS_CONFIG_RPM" cvmfs.yml
  
  # Add omicron-data repository
  cp /export/omicron-data.duckdns.org.pub /etc/cvmfs/keys
  cp /export/omicron-data.duckdns.org.conf /etc/cvmfs/config.d
  cp /export/default.local /etc/cvmfs

  # HACK: fix nodewatcher.py to work with UPDATE_COMPLETE stacks (this is fixed in AWS parallel-cluster, but we're still on cfncluster)
  sed -i.bak "s/'CREATE_COMPLETE'/'CREATE_COMPLETE' or stacks['Stacks'][0]['StackStatus'] == 'UPDATE_COMPLETE'/" /usr/local/lib/python2.7/site-packages/nodewatcher/nodewatcher.py
  
  # Use NFS version 4 instead of 3 and turn relatime on for root drive
  sed -i.bak "s/defaults,noatime/defaults/" /etc/fstab
  sed -i.bak "s/\(vers=3\)/vers=4/" /etc/fstab
  sed -i.bak "s/\(export.*_netdev\)/\1,fsc/" /etc/fstab

  # Install cachefilesd and enable FS-Cache for shared NFS mount
  yum install -y cachefilesd
  chkconfig cachefilesd on
  service cachefilesd start
  umount /export
  mount -a
  mount -o remount,relatime /

fi

true
