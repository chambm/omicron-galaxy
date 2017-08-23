#!/bin/bash
set -e

if (grep -q "MasterServer" /var/log/cfn-wire.log); then
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
  ln -s /export/galaxy-central /galaxy-central
  ln -s /export/shed_tools /shed_tools

  docker run --name omicron -d --restart=on-failure:10 --net=host \
    -v /export/:/export/ \
    -v /opt/slurm/:/opt/slurm/ \
    -v /etc/munge:/etc/munge \
    -e GALAXY_CONFIG_FTP_UPLOAD_SITE=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) \
    chambm/omicron-cfncluster

  docker exec omicron find / -uid 104 -exec chown -h $(id -u munge) {} + || 1
  docker exec omicron usermod -u $(id -u munge) munge
  docker exec omicron usermod -u $(id -u slurm) slurm
  docker exec omicron service munge start
  docker exec omicron cp -pr /galaxy_venv /export/galaxy_venv

  ln -s /export/galaxy_venv /galaxy_venv
  rm -f /galaxy_venv/python*
  virtualenv --always-copy --relocatable /galaxy_venv

  #Rscript --vanilla -e "install.packages(c('optparse', 'rjson'), repos='http://cran.rstudio.com/')"
  #Rscript --vanilla -e 'source("http://bioconductor.org/biocLite.R"); biocLite(ask=F)'
  #Rscript --vanilla -e 'source("https://raw.githubusercontent.com/chambm/devtools/master/R/easy_install.R"); devtools::install_github("chambm/customProDB")'
  #Rscript --vanilla -e 'source("http://bioconductor.org/biocLite.R"); biocLite(c("RGalaxy", "proBAMr"), ask=F)'
  tar cJf /export/R-lib.tar.xz /usr/lib64/R/library

else
  echo Compute

  cp -p /export/R-lib.tar.xz / && pushd / && tar xJf R-lib.tar.xz && popd

fi
