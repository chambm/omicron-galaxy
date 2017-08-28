#!/bin/bash
#set -e
. /opt/cfncluster/cfnconfig

if [ "$cfn_node_type" == "MasterServer" ]; then
  echo Master

  #echo manual | sudo tee /etc/init.d/httpd.override
  chkconfig --level 2345 httpd off
  service httpd stop

  #umount /dev/xvdb
  #btrfs-convert /dev/xvdb
  #sed -i.bak 's/\/export ext4 _netdev/\/export btrfs defaults,ssd,_netdev/' /etc/fstab
  #mount -a

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
    chambm/omicron-cfncluster:release_17.05

  while
    echo "Waiting for Galaxy to start"
    [[ $(docker exec omicron supervisorctl status galaxy:galaxy_web | grep -o RUNNING) != "RUNNING" ]]
  do
    sleep 1
  done

  container_munge_id=$(docker exec omicron id -u munge)
  docker exec omicron find / -uid $container_munge_id -exec chown -h $(id -u munge) {} + || true
  docker exec omicron usermod -u $(id -u munge) munge
  docker exec omicron usermod -u $(id -u slurm) slurm
  docker exec omicron service munge start
  #docker exec omicron cp -pr /galaxy_venv /export/galaxy_venv
  docker cp omicron:/etc/cvmfs/keys/omicron-data.duckdns.org.pub /export
  docker cp omicron:/etc/cvmfs/config.d/omicron-data.duckdns.org.conf /export
  docker cp omicron:/etc/cvmfs/default.local /export

  #ln -s /export/galaxy_venv /galaxy_venv
  #rm -f /galaxy_venv/python*
  #virtualenv --always-copy --relocatable /galaxy_venv

  #Rscript --vanilla -e "install.packages(c('optparse', 'rjson'), repos='http://cran.rstudio.com/')"
  #Rscript --vanilla -e 'source("http://bioconductor.org/biocLite.R"); biocLite(ask=F)'
  #Rscript --vanilla -e 'source("https://raw.githubusercontent.com/chambm/devtools/master/R/easy_install.R"); devtools::install_github("chambm/customProDB")'
  #Rscript --vanilla -e 'source("http://bioconductor.org/biocLite.R"); biocLite(c("RGalaxy", "proBAMr"), ask=F)'
  #tar cJf /export/R-lib.tar.xz /usr/lib64/R/library
fi

if [ "$cfn_node_type" == "ComputeFleet" ]; then
  echo Compute
  #cp -p /export/R-lib.tar.xz / && pushd / && tar xJf R-lib.tar.xz && popd
  useradd -u 1450 galaxy
  ln -s /export/galaxy-central /galaxy-central
  ln -s /export/shed_tools /shed_tools
  #ln -s /export/galaxy_venv /galaxy_venv

  mkdir /galaxy_venv
  wget https://raw.githubusercontent.com/chambm/omicron-galaxy/update_17.05/cfncluster/requirements.txt -O /galaxy_venv/requirements.txt
  chown -R $(id -u slurm):$(id -g slurm) /galaxy_venv
  virtualenv /galaxy_venv
  . /galaxy_venv/bin/activate
  pip install --upgrade pip
  pip install galaxy-lib
  pip install -r /galaxy_venv/requirements.txt --index-url https://wheels.galaxyproject.org/simple
  deactivate

  # Download galaxy-extras role for CVMFS task
  pip install ansible
  ansible-galaxy install git+https://github.com/galaxyproject/ansible-galaxy-extras.git,6ba80a218c1c7004c8d435c4b5a96b6235d53089

  # Create one-task playbook
  cat <<EOF > cvmfs.yml
- hosts: localhost
  tasks:
    - name: Setup CVMFS for compute node
      include_role:
        name: /etc/ansible/roles/ansible-galaxy-extras
        tasks_from: cvmfs_client.yml
EOF

  # Tweak CVMFS task to use yum
  sed -E -i.bak 's/apt: [^=]+=/yum: name=/' /etc/ansible/roles/ansible-galaxy-extras/tasks/cvmfs_client.yml
  sed -E -i.bak 's/\.deb/.rpm/' /etc/ansible/roles/ansible-galaxy-extras/tasks/cvmfs_client.yml
  CVMFS_RPM="http://cvmrepo.web.cern.ch/cvmrepo/yum/cvmfs/EL/5/x86_64/cvmfs-2.1.20-1.el5.x86_64.rpm"
  CVMFS_CONFIG_RPM="http://cvmrepo.web.cern.ch/cvmrepo/yum/cvmfs/EL/6/x86_64/cvmfs-config-default-1.2-2.noarch.rpm"

  # Download and install CVMFS
  ansible-playbook -e "galaxy_extras_install_packages=true galaxy_tool_data_table_config_file=/tmp/compute-notused cvmfs_deb_url=$CVMFS_RPM cvmfs_deb_config_url=$CVMFS_CONFIG_RPM" cvmfs.yml
  
  # Add omicron-data repository
  cp /export/omicron-data.duckdns.org.pub /etc/cvmfs/keys
  cp /export/omicron-data.duckdns.org.conf /etc/cvmfs/config.d
  cp /export/default.local /etc/cvmfs
fi

true