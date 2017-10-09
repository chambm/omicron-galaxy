# Galaxy - Omicron
#
# VERSION       Galaxy-central

FROM quay.io/bgruening/galaxy:17.05

MAINTAINER Matt Chambers, matt.chambers@vanderbilt.edu

# Add utility scripts
COPY *.sh /usr/bin/
RUN chmod u+x /usr/bin/*.sh && \
    tail -n 2 "scripts/api/upload_to_history.py" | wc -c | xargs -I {} truncate "scripts/api/upload_to_history.py" -s -{} && \
    echo "print(json.dumps(response))" >> scripts/api/upload_to_history.py

# "{owner: 'iuc'             ,name: 'sra_tools'                                      ,revisions: ['6c60903f70ac']  ,tool_panel_section_label: 'Get Data'}" \

ADD omicron-tools.yml $GALAXY_ROOT/tools.yaml

# Install Omicron tools into Galaxy
# 1. I don't know why the symbolic link to /opt/anaconda1anaconda2anaconda3 is necessary
# 2. Install nomkl package with numpy to avoid 500mb of extra libs for multiqc
# 3. Clean conda tarballs after install to save space
# 4. Remove documentation, test-data, and compiled python files to save space
RUN install-tools $GALAXY_ROOT/tools.yaml && \
    /tool_deps/_conda/bin/conda install -y -q -n __multiqc@1.0.0 nomkl numpy && \
    /tool_deps/_conda/bin/conda remove -y -q -n __multiqc@1.0.0 mkl mkl-service && \
    /tool_deps/_conda/bin/conda clean --tarballs --packages -y && \
    rm /export/galaxy-central/ -rf && \
    ln -s "/tool_deps/_conda/envs/__python@2.7.12" /opt/anaconda1anaconda2anaconda3 && \
    find /tool_deps/ /shed_tools/ -type f -regextype posix-egrep -iregex "(.*/man/.*)|(.*/doc/.*)|(.*/test-data/.*)" | xargs -n 1 cp /dev/null

# Add workflows and test data
COPY *.ga /tmp/
COPY test-data/* /tmp/

# Install Omicron workflows and test data (job_conf.xml must be moved because SLURM isn't running at this point)
RUN mv /etc/galaxy/job_conf.xml /etc/galaxy/job_conf.xml.bak && \
    start_galaxy.sh && \
    import_workflow.sh '/tmp/Galaxy-Workflow-2b._Proteomic_database_search_TMT6,_HCD,_MS-GF.ga' \
                       '/tmp/Galaxy-Workflow-2a._Proteomic_database_search_label-free,_CID,_MyriMatch.ga' \
                       '/tmp/Omicron-Workflow-1b_Create_sample-specific_protein_FASTAs_paired-end_collection_hg38,_HISAT_Freebayes.ga' \
                       '/tmp/Omicron-Workflow-1a_Create_sample-specific_protein_FASTAs_single-end_hg19,_TopHat_mpileup.ga' && \
    #upload_to_history.sh /tmp/hg19_subset.gtf /tmp/human_MCF7_subset.fastq && \
    stop_galaxy.sh && \
    mv /etc/galaxy/job_conf.xml.bak /etc/galaxy/job_conf.xml


# Test that the tools are persisting
RUN stat $GALAXY_ROOT/../shed_tools/*


# The following commands will be executed as user galaxy
USER galaxy

ENV GALAXY_CONFIG_BRAND="Omicron" \
    ENABLE_TTS_INSTALL=True

WORKDIR $GALAXY_ROOT

USER root

COPY cvmfs.yml .
RUN pip install ansible && \
    apt-get update -q && \
    ansible-galaxy install --roles-path ~/roles git+https://github.com/galaxyproject/ansible-galaxy-extras.git,6ba80a218c1c7004c8d435c4b5a96b6235d53089 && \
    ansible-playbook -e "galaxy_extras_install_packages=true galaxy_tool_data_table_config_file=$GALAXY_ROOT/config/tool_data_table_conf.xml" cvmfs.yml && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY omicron-data.duckdns.org.pub /etc/cvmfs/keys/
COPY omicron-data.duckdns.org.conf /etc/cvmfs/config.d/
COPY default.local /etc/cvmfs/

# 1. Add hisat2 and customProDB indexes to /etc/galaxy/tool_data_table_conf.xml
# 2. Set passive port range for proFTPd (this port range must match the ports opened by the host)
# 3. Add 'Input is VCF' option to the bcftools_view tool
# 4. Make TopHat2 wrapper ignore Exception and Error messages in the log text - only non-zero exit code will be fatal.
RUN sed -i.bak 's/<\/tables>/    <table name="hisat2_indexes" comment_char="#"><columns>value, dbkey, name, path<\/columns><file path="\/cvmfs\/data.galaxyproject.org\/managed\/location\/hisat2_indexes.loc" \/><\/table>\n<\/tables>/' $GALAXY_ROOT/config/tool_data_table_conf.xml && \
    sed -i.bak 's/<\/tables>/    <table name="customProDB" comment_char="#"><columns>value, dbkey, name, path<\/columns><file path="\/cvmfs\/omicron-data.duckdns.org\/customProDB\/customProDB.loc" \/><\/table>\n<\/tables>/' $GALAXY_ROOT/config/tool_data_table_conf.xml && \
    sed -i.bak 's/^\(PassivePorts\).*/\1 30000 30100/' /etc/proftpd/proftpd.conf && \
    sed -i.bak 's/\(\s*\)\(<regex match="Exception|Error" source="both"\) level="fatal" description="Tool execution failed"/\1<exit_code range="1:" level="fatal" description="Tool execution failed" \/>\n\1\2 level="log" description="Warning"/' $GALAXY_ROOT/../shed_tools/toolshed.g2.bx.psu.edu/repos/devteam/tophat2/16c4255042be/tophat2/tophat2_wrapper.xml && \
    echo '[program:autofs]\n\
user            = root\n\
command         = /usr/sbin/automount -f\n\
autostart       = true\n\
autorestart     = true\n'\
    > /etc/supervisor/conf.d/autofs.conf

# Container Style
#ADD GalaxyDocker.png $GALAXY_CONFIG_DIR/web/welcome_image.png
#ADD welcome.html $GALAXY_CONFIG_DIR/web/welcome.html

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9009 (toolshed)
EXPOSE :80 :21 :8800 :9009

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]