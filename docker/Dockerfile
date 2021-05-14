# Galaxy - Omicron
#
# VERSION       Galaxy-central

FROM quay.io/bgruening/galaxy:19.09

LABEL MAINTAINER="Matt Chambers, matt.chambers42@gmail.com"

# Add utility scripts
RUN tail -n 2 "scripts/api/upload_to_history.py" | wc -c | xargs -I {} truncate "scripts/api/upload_to_history.py" -s -{} && \
    echo "print(json.dumps(response))" >> scripts/api/upload_to_history.py

# "{owner: 'iuc'             ,name: 'sra_tools'                                      ,revisions: ['6c60903f70ac']  ,tool_panel_section_label: 'Get Data'}" \

ADD omicron-tools.yml $GALAXY_ROOT/tools.yaml

# Install Omicron tools into Galaxy
# - Clean conda tarballs after install to save space
# - Remove documentation, test-data, and compiled python files to save space
RUN install-tools $GALAXY_ROOT/tools.yaml && \
    /tool_deps/_conda/bin/conda clean --tarballs --packages -y && \
    rm /export/galaxy-central/ -rf && \
    find /tool_deps/ /shed_tools/ -type f -regextype posix-egrep -iregex "(.*/man/.*)|(.*/doc/.*)|(.*/test-data/.*)" | xargs -n 1 cp /dev/null
#    ln -s "/tool_deps/_conda/envs/__python@2.7.12" /opt/anaconda1anaconda2anaconda3 && \


ENV GALAXY_CONFIG_CONDA_AUTO_INSTALL=true
#ADD omicron-tools2.yml $GALAXY_ROOT/tools.yaml

#RUN install-tools $GALAXY_ROOT/tools.yaml && \
#    /tool_deps/_conda/bin/conda clean --tarballs -y && \
#    rm /export/galaxy-central/ -rf && \
#    find /tool_deps/ /shed_tools/ -type f -regextype posix-egrep -iregex "(.*/man/.*)|(.*/doc/.*)|(.*/test-data/.*)" | xargs -n 1 cp /dev/null

#RUN cp /tool_deps/_conda/pkgs/samtools-1.5-2/bin/* /usr/bin
#RUN cp /tool_deps/_conda/pkgs/bcftools-1.4.1-0/bin/* /usr/bin

# Add workflows and test data
COPY *.ga /tmp/
#COPY test-data/* /tmp/

COPY *.sh /usr/bin/
RUN chmod u+x /usr/bin/*.sh
ENV GALAXY_LOG=galaxy_install.log
# Install Omicron workflows and test data (job_conf.xml must be moved because SLURM isn't running at this point)
RUN mv /etc/galaxy/job_conf.xml /etc/galaxy/job_conf.xml.bak && \
    chown galaxy:galaxy config/* && \
    start_galaxy.sh && \
    import_workflow.sh '/tmp/Galaxy-Workflow-Proteomic_database_search_iTRAQ4,_HCD,_MS-GF_.ga' \
                       '/tmp/Galaxy-Workflow-Proteomic_database_search_LabelFree,_HCD,_MS-GF_.ga' \
                       '/tmp/Galaxy-Workflow-Proteomic_database_search_TMT6,_HCD,_MS-GF_.ga' \
                       '/tmp/Galaxy-Workflow-Proteomic_database_search_TMT10,_HCD,_MS-GF_.ga' \
                       '/tmp/Omicron-Workflow-1b_Create_sample-specific_protein_FASTAs_paired-end_collection_hg38,_HISAT_Freebayes.ga' \
                       '/tmp/Omicron-Workflow-1a_Create_sample-specific_protein_FASTAs_single-end_hg19,_TopHat_mpileup.ga' && \
    #upload_to_history.sh /tmp/hg19_subset.gtf /tmp/human_MCF7_subset.fastq && \
    stop_galaxy.sh && \
    mv /etc/galaxy/job_conf.xml.bak /etc/galaxy/job_conf.xml


# Test that the tools are persisting
RUN stat $GALAXY_ROOT/database/shed_tools/*


# The following commands will be executed as user galaxy
USER galaxy

ENV GALAXY_CONFIG_BRAND="Omicron" \
    ENABLE_TTS_INSTALL=True

WORKDIR $GALAXY_ROOT

USER root

COPY omicron-data.duckdns.org.pub /etc/cvmfs/keys/
COPY omicron-data.duckdns.org.conf /etc/cvmfs/config.d/
COPY default.local /etc/cvmfs/

# - Add hisat2 and customProDB indexes to /etc/galaxy/tool_data_table_conf.xml
# - Set passive port range for proFTPd (this port range must match the ports opened by the host)
# - Make TopHat2 wrapper ignore Exception and Error messages in the log text - only non-zero exit code will be fatal.
# - Make supervisor web service only listen on loopback IP
RUN sed -i.bak 's/<\/tables>/    <table name="hisat2_indexes" comment_char="#"><columns>value, dbkey, name, path<\/columns><file path="\/cvmfs\/data.galaxyproject.org\/managed\/location\/hisat2_indexes.loc" \/><\/table>\n<\/tables>/' $GALAXY_CONFIG_TOOL_DATA_TABLE_CONFIG_PATH && \
    sed -i.bak 's/<\/tables>/    <table name="customProDB" comment_char="#"><columns>value, dbkey, name, path<\/columns><file path="\/cvmfs\/omicron-data.duckdns.org\/customProDB\/customProDB.loc" \/><\/table>\n<\/tables>/' $GALAXY_CONFIG_TOOL_DATA_TABLE_CONFIG_PATH && \
    sed -i.bak 's/^\(PassivePorts\).*/\1 30000 30100/' /etc/proftpd/proftpd.conf && \
    sed -i.bak 's/\(\s*\)\(<regex match="Exception|Error" source="both"\) level="fatal" description="Tool execution failed"/\1<exit_code range="1:" level="fatal" description="Tool execution failed" \/>\n\1\2 level="log" description="Warning"/' $GALAXY_ROOT/database/shed_tools/toolshed.g2.bx.psu.edu/repos/devteam/tophat2/16c4255042be/tophat2/tophat2_wrapper.xml && \
    sed -i.bak 's/0.0.0.0:9002/127.0.0.1:9002/' /etc/supervisor/conf.d/galaxy.conf

# Container Style
#ADD GalaxyDocker.png $GALAXY_CONFIG_DIR/web/welcome_image.png
#ADD welcome.html $GALAXY_CONFIG_DIR/web/welcome.html

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9009 (toolshed)
EXPOSE :80 :21 :8800 :9009

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
