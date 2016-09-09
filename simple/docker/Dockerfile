# Galaxy - Omicron simple
#
# VERSION       Galaxy-central

FROM bgruening/galaxy-stable

MAINTAINER Matt Chambers, matt.chambers@vanderbilt.edu

# Install various tool and development requirements
# 1. Cleanup
RUN apt-get -qq update && \
    apt-get install -y --no-install-recommends cabextract build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libxml2-dev libexpat-dev libncurses-dev zlib1g-dev libreadline-dev && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Note: do not install files to volumes from the Dockerfile; they won't persist

# Install simple Omicron tools into Galaxy
RUN add-tool-shed --url 'http://testtoolshed.g2.bx.psu.edu/' --name 'Test Tool Shed' && \
    install-repository "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name myrimatch" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name idpqonvert" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name idpassemble" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name idpquery"

# The following commands will be executed as user galaxy
USER galaxy

ENV GALAXY_CONFIG_BRAND="Omicron (simple)" \
    ENABLE_TTS_INSTALL=True

WORKDIR $GALAXY_ROOT

USER root

COPY *.ga /tmp/
COPY import_workflow.sh /usr/bin/import-workflow
RUN import-workflow /tmp/*.ga

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9009 (toolshed)
EXPOSE :80 :21 :8800 :9009

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]