# Galaxy Omicron - CfnCluster edition
#
# VERSION       Galaxy-central

FROM chambm/omicron-galaxy:release_17.05

MAINTAINER Matt Chambers, matt.chambers@vanderbilt.edu

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5E25F516B04C661B A6BFD95994EE84A6 && \
    echo "deb http://ppa.launchpad.net/mertes/slurm/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/slurm-trusty.list && \
    apt-get update -q && \
    apt-get autoremove -y slurm-llnl slurm-drmaa1 && \
    apt-get install -y slurm=15-08-7-1-ppa2+2004 libslurm-dev=15-08-7-1-ppa2+2004 && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo OPTIONS=\"--force\" >> /etc/default/munge

ENV NONUSE=reports,slurmd,slurmctld \
    SLURM_CONF=/opt/slurm/etc/slurm.conf \
    GALAXY_CONFIG_ALLOW_USER_DATASET_PURGE=True \
    GALAXY_CONFIG_ENABLE_QUOTAS=True \
    GALAXY_CONFIG_NGINX_UPLOAD_STORE=/export/nginx_upload_store \
    GALAXY_CONFIG_RETRY_JOB_OUTPUT_COLLECTION=60

RUN mkdir /src && cd /src && curl http://apps.man.poznan.pl/trac/slurm-drmaa/downloads/9 | tar xz && \
    cd /src/slurm-drmaa-1.0.7 && \
    ./configure && make && make install && \
    rm -fr /src

ADD job_conf.xml $GALAXY_CONFIG_JOB_CONFIG_FILE
ADD slurm_prolog.sh /usr/bin/
ENV DRMAA_LIBRARY_PATH=/usr/local/lib/libdrmaa.so

# 1. Change upload directory in nginx.conf
# 2. Change SFTP to use port 8022
RUN sed -i.bak "s/upload_store \/tmp\/nginx_upload_store/upload_store \/export\/nginx_upload_store/" /etc/nginx/nginx.conf && \
    sed -i.bak "s/\(\s*Port\s*\) 22/\1 8022/" /etc/proftpd/proftpd.conf

VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8022 (SFTP server)
EXPOSE :80 :21 :8022

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]