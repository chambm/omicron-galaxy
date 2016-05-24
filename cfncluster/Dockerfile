# Galaxy Omicron - CfnCluster edition
#
# VERSION       Galaxy-central

FROM chambm/omicron-galaxy

MAINTAINER Matt Chambers, matt.chambers@vanderbilt.edu

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5E25F516B04C661B A6BFD95994EE84A6 && \
    echo "deb http://ppa.launchpad.net/mertes/slurm/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/slurm-trusty.list && \
    apt-get update -q && \
    apt-get autoremove -y slurm-llnl && \
    apt-get install -y slurm=15-08-7-1-ppa2+2004 && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo OPTIONS=\"--force\" >> /etc/default/munge

ENV NONUSE=reports,slurmd,slurmctld \
    SLURM_CONF=/opt/slurm/etc/slurm.conf \
    GALAXY_CONFIG_ALLOW_USER_DATASET_PURGE=True \
    GALAXY_CONFIG_ENABLE_QUOTAS=True

RUN mkdir /src && cd /src && curl http://apps.man.poznan.pl/trac/slurm-drmaa/downloads/9 | tar xz
RUN cd /src/slurm-drmaa-1.0.7 && \
    ./configure && make && make install && \
    rm -fr /src

RUN sed -i.bak 's/^\(PassivePorts\).*/\1 30000 30100/' /etc/proftpd/proftpd.conf

VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9009 (toolshed)
EXPOSE :80 :21 :8800 :9009

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]