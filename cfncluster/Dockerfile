# Galaxy Omicron - CfnCluster edition
#
# VERSION       Galaxy-central

FROM chambm/omicron-galaxy:release_19.09

RUN echo OPTIONS=\"--force\" >> /etc/default/munge

ENV NONUSE=reports,slurmd,slurmctld \
    SLURM_CONF=/opt/slurm/etc/slurm.conf \
    GALAXY_CONFIG_ALLOW_USER_DATASET_PURGE=True \
    GALAXY_CONFIG_ENABLE_QUOTAS=True \
    GALAXY_CONFIG_NGINX_UPLOAD_STORE=/export/nginx_upload_store \
    GALAXY_CONFIG_RETRY_JOB_OUTPUT_COLLECTION=60


# Copy slurm include/lib from host (to build slurm-drmaa against the same verison of slurm)
# mkdir slurm && cp -r /opt/slurm/include/ /opt/slurm/lib/ slurm
ADD slurm/include /usr/local/include/slurm/include
ADD slurm/lib /usr/local/lib/slurm/lib

# Build slurm-drmaa from source against host's slurm version
RUN apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com && \
    apt-get update -q && \
    apt-get install -y gcc make && \
    mkdir /src && cd /src && curl -L https://github.com/natefoo/slurm-drmaa/releases/download/1.1.2/slurm-drmaa-1.1.2.tar.gz | tar xz && \
    cd slurm-drmaa-1.1.2 && \
    ./configure --with-slurm-inc=/usr/local/include/slurm/include --with-slurm-lib=/usr/local/lib/slurm/lib && \
    make && make install && \
    apt-get autoremove -y gcc make && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
