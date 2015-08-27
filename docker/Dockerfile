# Galaxy - Bingomics
#
# VERSION       Galaxy-central

FROM chambm/docker-galaxy-stable

MAINTAINER Matt Chambers, matt.chambers@vanderbilt.edu

# Install 32-bit Wine and linuxbrew requirements
# 1. Add i386 architecture and run apt-get update
# 2. Install wine and xvfb (console frame buffer for X11)
# 3. Install linuxbrew requirements
# 4. Install libhdf5-dev (for building h5py)
# 5. Download winetricks from their site and make it executable
# 6. Cleanup
RUN dpkg --add-architecture i386 && apt-get -qq update && \
    apt-get install -y --no-install-recommends wine xvfb cabextract build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev libhdf5-dev python-h5py && \
    wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && chmod ugo+rx winetricks && chown galaxy:galaxy winetricks && mv winetricks /usr/local/bin && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Packages
RUN add-tool-shed --url 'http://testtoolshed.g2.bx.psu.edu/' --name 'Test Tool Shed' && \
    install-repository "--url http://testtoolshed.g2.bx.psu.edu/ -o chambm --name myrimatch" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o chambm --name idpqonvert" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o chambm --name idpassemble" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o chambm --name idpquery"

# The following commands will be executed as user galaxy
USER galaxy

# Install linuxbrew (can't be done as root) and add it to the PATH
# add Brew to PATH for galaxy user (this hack is needed because of https://github.com/docker/docker/issues/15383)
RUN ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" && \
    echo export PATH=$PATH:/home/galaxy/.linuxbrew/bin >> /home/galaxy/.bashrc && \
    cat /home/galaxy/.bashrc

# BASH_ENV tells bash what to do for non-interactive logins
ENV PATH=$PATH:/home/galaxy/.linuxbrew/bin BASH_ENV=/home/galaxy/.bashrc

# Install planemo (will be installed in linuxbrew's bin directory)
RUN brew tap galaxyproject/tap && brew install planemo

ENV GALAXY_CONFIG_BRAND="Bingomics" \
    GALAXY_CONFIG_JOB_WORKING_DIRECTORY=/export/galaxy-cluster/job_working_directory \
    GALAXY_CONFIG_FILE_PATH=/export/galaxy-central/database/files \
    GALAXY_CONFIG_NEW_FILE_PATH=/export/galaxy-central/database/files \
    GALAXY_CONFIG_TEMPLATE_CACHE_PATH=/galaxy-central/database/compiled_templates \
    GALAXY_CONFIG_CITATION_CACHE_DATA_DIR=/galaxy-central/database/citations/data \
    GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY=/export/galaxy-cluster/pbs \
    GALAXY_CONFIG_FTP_UPLOAD_DIR=/export/galaxy-central/database/ftp \
    GALAXY_CONFIG_FTP_UPLOAD_SITE=192.168.33.10 \
    ENABLE_TTS_INSTALL=True

WORKDIR /galaxy-central

# Install h5py and its dependencies
# TODO: why isn't Galaxy's python running in venv? $GALAXY_VIRTUALENV/bin/activate
# RUN rm $GALAXY_ROOT/lib/pkg_resources.py* && pip install Cython numpy && pip install h5py

# set WINEPREFIX and WINEARCH for galaxy user
ENV WINEPREFIX=$HOME/.wine32 WINEARCH=win32

#RUN xvfb-run winetricks -q winxp vcrun2005 win7 vcrun2008 vcrun2010 vcrun2012 vcrun2013
#RUN xvfb-run winetricks -q dotnet35sp1 dotnet40

#RUN export PWIZPATH="/home/vagrant/pwiz-bin-windows-x86"
#RUN echo export PWIZPATH=$PWIZPATH >> $HOME/.bashrc

#RUN mkdir $PWIZPATH
#RUN tar xjf /vagrant/pwiz-bin-windows-x86-*.tar.bz2 -C $PWIZPATH

# register MSFileReader and CompassXtract (side by side COM doesn't seem to work in wine)
#RUN xvfb-run wine regsvr32 /s $PWIZPATH/MSFileReader.XRawfile2.dll
# broken: RUN xvfb-run wine regsvr32 /s $PWIZPATH/CompassXtractMS.dll

# add pwiz to vagrant user path
#RUN echo export PATH=$PWIZPATH:$PATH >> /home/vagrant/.bashrc


USER root

RUN mkdir /export/galaxy-cluster && chown galaxy:galaxy /export/galaxy-cluster

# Updating genome informations from UCSC
#RUN export GALAXY=/galaxy-central && sh ./cron/updateucsc.sh.sample

# Container Style
#ADD GalaxyDocker.png $GALAXY_CONFIG_DIR/web/welcome_image.png
#ADD welcome.html $GALAXY_CONFIG_DIR/web/welcome.html

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9009 (toolshed)
EXPOSE :80 :21 :8800 :9009

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]