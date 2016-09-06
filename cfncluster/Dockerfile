# Galaxy Omicron - CfnCluster edition
#
# VERSION       Galaxy-central

FROM chambm/omicron-galaxy

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
ENV DRMAA_LIBRARY_PATH=/usr/local/lib/libdrmaa.so

# 1. Set passive port range for proFTPd (this port range must match the ports opened by the CFN template)
# 2. Add 'Input is VCF' option to the bcftools_view tool
# 3. Change upload directory in nginx.conf
# 4. Make TopHat2 wrapper ignore Exception and Error messages in the log text - only non-zero exit code will be fatal.
RUN sed -i.bak 's/^\(PassivePorts\).*/\1 30000 30100/' /etc/proftpd/proftpd.conf && \
    sed -i.bak 's/$varsitesonly/$S $varsitesonly/' $GALAXY_ROOT/../shed_tools/toolshed.g2.bx.psu.edu/repos/iuc/bcftools/e5e78d1e09a6/bcftools/bcftools_view.xml && \
    sed -i.bak 's/\(        <param name="input" type="data" format="bcf,vcf" label="Choose a bcf file to view" \/>\)/\1\n        <param name="S" type="boolean" truevalue="-S" falsevalue="" checked="False" label="Input is VCF" help="-S" \/>/' $GALAXY_ROOT/../shed_tools/toolshed.g2.bx.psu.edu/repos/iuc/bcftools/e5e78d1e09a6/bcftools/bcftools_view.xml && \
    sed -i.bak "s/upload_store \/tmp\/nginx_upload_store/upload_store \/export\/nginx_upload_store/" /etc/nginx/nginx.conf && \
    sed -i.bak 's/\(\s*\)\(<regex match="Exception|Error" source="both"\) level="fatal" description="Tool execution failed"/\1<exit_code range="1:" level="fatal" description="Tool execution failed" \/>\n\1\2 level="log" description="Warning"/' $GALAXY_ROOT/../shed_tools/toolshed.g2.bx.psu.edu/repos/devteam/tophat2/758594ed0364/tophat2/tophat2_wrapper.xml

# Make Galaxy venv relocatable and use copies instead of  links
RUN virtualenv --always-copy --relocatable $GALAXY_VIRTUAL_ENV

VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9009 (toolshed)
EXPOSE :80 :21 :8800 :9009

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]