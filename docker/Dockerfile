# Galaxy - Omicron
#
# VERSION       Galaxy-central

FROM bgruening/galaxy-stable:19.01

MAINTAINER Matt Chambers, matt.chambers@vanderbilt.edu

# Install various tool and development requirements
# 1. Add R-dev PPA and its public key (then 'apt-get update')
# 2. Install R-3.2 from R-dev PPA
# 3. Cleanup
RUN codename=$(lsb_release -c -s) && \
    echo "deb http://mirrors.nics.utk.edu/cran/bin/linux/ubuntu $codename/" | tee -a /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9 && \
    echo "deb http://ppa.launchpad.net/marutter/rdev/ubuntu $codename main" | tee -a /etc/apt/sources.list.d/marutter-rdev-$codename.list && \
    apt-get -qq update && \
    apt-get install -y --no-install-recommends r-base r-cran-rjson cabextract build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libxml2-dev libexpat-dev libncurses-dev zlib1g-dev libreadline-dev && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install BioConductor and proBAMr
RUN R --vanilla -e 'source("http://bioconductor.org/biocLite.R"); biocLite(ask=F)' && \
	R --vanilla -e 'source("https://raw.githubusercontent.com/chambm/devtools/master/R/easy_install.R"); devtools::install_github("chambm/customProDB")' && \
    R --vanilla -e 'source("http://bioconductor.org/biocLite.R"); biocLite(c("RGalaxy", "proBAMr"), ask=F)'

# Note: do not install files to volumes from the Dockerfile; they won't persist

# Install standard Omicron tools into Galaxy
RUN install-repository "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name data_manager_sam_fasta_index_builder" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name data_manager_fetch_genome_all_fasta" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name samtools_mpileup" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name sam_to_bam" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name sam_merge"

# Test that the tools are persisting
RUN stat $GALAXY_ROOT/../shed_tools/*

# Install custom Omicron tools into Galaxy
RUN add-tool-shed --url 'http://testtoolshed.g2.bx.psu.edu/' --name 'Test Tool Shed' && \
    install-repository "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name myrimatch" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name idpqonvert" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name idpassemble" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name idpquery" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name msconvert" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name psm_to_sam" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name custom_pro_db" \
                       "--url http://testtoolshed.g2.bx.psu.edu/ -o galaxyp --name custom_pro_db_annotation_data_manager" 

RUN install-repository "--url http://toolshed.g2.bx.psu.edu/ -o galaxyp --name fasta_merge_files_and_filter_unique_sequences" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name tophat2" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name fastq_groomer" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name data_manager_bowtie2_index_builder" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o iuc --name bcftools" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name vcffilter" \
                       "--url http://toolshed.g2.bx.psu.edu/ -o devteam --name bamtools"

# The following commands will be executed as user galaxy
USER galaxy

ENV GALAXY_CONFIG_BRAND="Omicron" \
    ENABLE_TTS_INSTALL=True

WORKDIR $GALAXY_ROOT

USER root

COPY *.ga /tmp/
COPY import_workflow.sh /usr/bin/import-workflow
RUN import-workflow /tmp/Omicron-Workflow-3b_Myrimatch_for_label-free.ga \
                    /tmp/Omicron-Workflow-3a_Create_sample-specific_protein_FASTAs.ga \
                    /tmp/Omicron-Workflow-2_Index_hg19_genome.ga \
                    /tmp/Omicron-Workflow-1_Download_hg19_reference_genome.ga
                    
                    


# Container Style
#ADD GalaxyDocker.png $GALAXY_CONFIG_DIR/web/welcome_image.png
#ADD welcome.html $GALAXY_CONFIG_DIR/web/welcome.html

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9009 (toolshed)
EXPOSE :80 :21 :8800 :9009

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
