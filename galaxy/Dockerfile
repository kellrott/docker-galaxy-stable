# Galaxy - Stable
#
# VERSION       Galaxy-central

FROM toolshed/requirements

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

# * Make sure the package repository is up to date
# * Install all requirements that are recommend by the Galaxy project
# * Enable the @natefoo magic
# Web server infrastructure matching usegalaxy.org - supervisor, uwsgi, and nginx.

ENV GALAXY_RELEASE=release_15.07 \
GALAXY_REPO=https://github.com/galaxyproject/galaxy \
GALAXY_ROOT=/galaxy-central \
GALAXY_CONFIG_DIR=/etc/galaxy

ENV GALAXY_CONFIG_FILE=$GALAXY_CONFIG_DIR/galaxy.ini \
GALAXY_CONFIG_JOB_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_conf.xml \
GALAXY_CONFIG_JOB_METRICS_CONFIG_FILE=$GALAXY_CONFIG_DIR/job_metrics_conf.xml \
GALAXY_VIRTUALENV=/home/galaxy/venv \
GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450 \
GALAXY_POSTGRES_UID=1550 \
GALAXY_POSTGRES_GID=1550 \
GALAXY_HOME=/home/galaxy \
GALAXY_DEFAULT_ADMIN_USER=admin@galaxy.org \
GALAXY_DEFAULT_ADMIN_PASSWORD=admin \
GALAXY_DEFAULT_ADMIN_KEY=admin \
EXPORT_DIR=/export

# Create the postgres user before apt-get does (with the configured UID/GID) to facilitate sharing /export/postgresql with non-Linux hosts
RUN groupadd -r postgres -g $GALAXY_POSTGRES_GID && \
    adduser --system --quiet --home /var/lib/postgresql --no-create-home --shell /bin/bash --gecos "" --uid $GALAXY_POSTGRES_UID --gid $GALAXY_POSTGRES_GID postgres

RUN apt-get -qq update && apt-get install --no-install-recommends -y apt-transport-https software-properties-common && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9 && \
    sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list" && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt-add-repository -y ppa:galaxyproject/nginx && \
    apt-get update -qq && apt-get upgrade -y && \
    apt-get install --no-install-recommends -y mercurial python-psycopg2 postgresql-9.3 sudo samtools python-virtualenv wget \
    nginx-extras nginx-common uwsgi uwsgi-plugin-python supervisor lxc-docker-1.7.1 slurm-llnl slurm-llnl-torque libswitch-perl \
    slurm-drmaa-dev proftpd proftpd-mod-pgsql libyaml-dev nodejs-legacy npm aufs-tools ansible \
    nano nmap lynx vim curl python-pip && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
    mkdir $EXPORT_DIR $GALAXY_HOME && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_HOME $EXPORT_DIR && \
    gpasswd -a $GALAXY_USER docker

# Download latest stable release of Galaxy.
RUN mkdir $GALAXY_ROOT && wget -q -O - $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_ROOT

# TODO: ensure virtualenv as part of galaxy role
RUN su $GALAXY_USER -c "virtualenv $GALAXY_VIRTUALENV"

# Setup Galaxy configuration files.
RUN mkdir -p $GALAXY_CONFIG_DIR $GALAXY_CONFIG_DIR/web && chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_CONFIG_DIR

RUN su $GALAXY_USER -c "cp $GALAXY_ROOT/config/galaxy.ini.sample $GALAXY_CONFIG_FILE"
ADD ./reports_wsgi.ini.sample $GALAXY_CONFIG_DIR/reports_wsgi.ini
ADD ./htpasswd /etc/nginx/htpasswd
ADD ./servers.ini $GALAXY_CONFIG_DIR/servers.ini
RUN cat $GALAXY_CONFIG_DIR/servers.ini >> $GALAXY_CONFIG_FILE && rm $GALAXY_CONFIG_DIR/servers.ini
ADD roles/ /tmp/ansible/roles
ADD provision.yml /tmp/ansible/provision.yml
RUN ansible-playbook /tmp/ansible/provision.yml \
    --extra-vars galaxy_user_name=$GALAXY_USER \
    --extra-vars galaxy_config_file=$GALAXY_CONFIG_FILE \
    --extra-vars galaxy_config_dir=$GALAXY_CONFIG_DIR \
    --extra-vars galaxy_job_conf_path=$GALAXY_CONFIG_JOB_CONFIG_FILE \
    --extra-vars galaxy_job_metrics_conf_path=$GALAXY_CONFIG_JOB_METRICS_CONFIG_FILE \
    --extra-vars supervisor_manage_slurm="" \
    --tags=galaxyextras -c local && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD roles/ /tmp/ansible/roles
ADD provision.yml /tmp/ansible/provision.yml

RUN mkdir /shed_tools && chown $GALAXY_USER:$GALAXY_USER /shed_tools

# The following commands will be executed as User galaxy
USER galaxy

WORKDIR /galaxy-central

# Configure Galaxy to use the Tool Shed
RUN mkdir $GALAXY_ROOT/tool_deps

# Fetching all Galaxy python dependencies
RUN . $GALAXY_VIRTUALENV/bin/activate && python scripts/fetch_eggs.py -c $GALAXY_CONFIG_FILE && python scripts/fetch_eggs.py -e drmaa -c $GALAXY_CONFIG_FILE

# Updating genome informations from UCSC
#RUN export GALAXY=/galaxy-central && sh ./cron/updateucsc.sh.sample

ENV GALAXY_CONFIG_DATABASE_CONNECTION=postgresql://galaxy:galaxy@localhost:5432/galaxy \
GALAXY_CONFIG_TOOL_DEPENDENCY_DIR=./tool_deps \
GALAXY_CONFIG_ADMIN_USERS=admin@galaxy.org \
GALAXY_CONFIG_MASTER_API_KEY=HSNiugRFvgT574F43jZ7N9F3 \
GALAXY_CONFIG_BRAND="Galaxy Docker Build" \
GALAXY_CONFIG_STATIC_ENABLED=False \
GALAXY_CONFIG_JOB_WORKING_DIRECTORY=/export/galaxy-central/database/job_working_directory \
GALAXY_CONFIG_FILE_PATH=/export/galaxy-central/database/files \
GALAXY_CONFIG_NEW_FILE_PATH=/export/galaxy-central/database/files \
GALAXY_CONFIG_TEMPLATE_CACHE_PATH=/export/galaxy-central/database/compiled_templates \
GALAXY_CONFIG_CITATION_CACHE_DATA_DIR=/export/galaxy-central/database/citations/data \
GALAXY_CONFIG_CLUSTER_FILES_DIRECTORY=/export/galaxy-central/database/pbs \
GALAXY_CONFIG_FTP_UPLOAD_DIR=/export/galaxy-central/database/ftp \
GALAXY_CONFIG_FTP_UPLOAD_SITE=galaxy.docker.org \
GALAXY_CONFIG_USE_PBKDF2=False \
GALAXY_CONFIG_NGINX_X_ACCEL_REDIRECT_BASE=/_x_accel_redirect \
GALAXY_CONFIG_NGINX_X_ARCHIVE_FILES_BASE=/_x_accel_redirect \
GALAXY_CONFIG_NGINX_UPLOAD_STORE=/tmp/nginx_upload_store \
GALAXY_CONFIG_NGINX_UPLOAD_PATH=/_upload \
GALAXY_CONFIG_DYNAMIC_PROXY_MANAGE=False \
GALAXY_CONFIG_VISUALIZATION_PLUGINS_DIRECTORY=config/plugins/visualizations \
GALAXY_CONFIG_TRUST_IPYTHON_NOTEBOOK_CONVERSION=True \
GALAXY_CONFIG_TOOLFORM_UPGRADE=True \
# Next line allow child docker container for viz to find this docker container.
GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL=http://$HOST_IP/ \
GALAXY_CONFIG_SANITIZE_ALL_HTML=False \
GALAXY_CONFIG_TOOLFORM_UPGRADE=True \
GALAXY_CONFIG_WELCOME_URL=$GALAXY_CONFIG_DIR/web/welcome.html \
GALAXY_CONFIG_OVERRIDE_DEBUG=False

# Define the default postgresql database path
ENV PG_DATA_DIR_DEFAULT=/var/lib/postgresql/9.3/main/ \
PG_DATA_DIR_HOST=/export/postgresql/9.3/main/


# Install all required Node dependencies. This is required to get proxy support to work for Interactive Environments
RUN  cd /galaxy-central/lib/galaxy/web/proxy/js && npm install

# Container Style
ADD GalaxyDocker.png $GALAXY_CONFIG_DIR/web/welcome_image.png
ADD welcome.html $GALAXY_CONFIG_DIR/web/welcome.html

# Switch back to User root
USER root

# Setting a standard encoding. This can get important for things like the unix sort tool.
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

# Include all needed scripts from the host
ADD ./setup_postgresql.py /usr/local/bin/setup_postgresql.py
ADD ./export_user_files.py /usr/local/bin/export_user_files.py

# workaround for a Docker AUFS bug: https://github.com/docker/docker/issues/783#issuecomment-56013588
#RUN mkdir /etc/ssl/private-copy; mv /etc/ssl/private/* /etc/ssl/private-copy/; rm -r /etc/ssl/private; mv /etc/ssl/private-copy /etc/ssl/private; chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private

# Configure PostgreSQL
# 1. Remove all old configuration
# 2. Create DB-user 'galaxy' with password 'galaxy' in database 'galaxy'
# 3. Create Galaxy Admin User 'admin@galaxy.org' with password 'admin' and API key 'admin'

RUN rm $PG_DATA_DIR_DEFAULT -rf && python /usr/local/bin/setup_postgresql.py --dbuser galaxy --dbpassword galaxy --db-name galaxy --dbpath $PG_DATA_DIR_DEFAULT
ADD ./create_galaxy_user.py /usr/local/bin/create_galaxy_user.py
RUN service postgresql start && \
    sh create_db.sh -c $GALAXY_CONFIG_FILE && \
    python /usr/local/bin/create_galaxy_user.py --user $GALAXY_DEFAULT_ADMIN_USER --password $GALAXY_DEFAULT_ADMIN_PASSWORD -c $GALAXY_CONFIG_FILE --key $GALAXY_DEFAULT_ADMIN_KEY && \
    service postgresql stop

# Activate additional Tool Sheds
# Activate the Test Tool Shed during runtime, useful for testing repositories.
ADD ./tool_sheds_conf.xml $GALAXY_HOME/tool_sheds_conf.xml
# Activate arbritrary Tool Sheds during build-time by manipulating the original tool_sheds_conf.xml file
ADD ./add_tool_shed.py /usr/bin/add-tool-shed

ADD ./startup.sh /usr/bin/startup
# script that enables easier downstream installation of tools (e.g. for different Galaxy Docker flavours)
ADD install_repo_wrapper.sh /usr/bin/install-repository
# script to install BioJS visualizations
ADD install_biojs_vis.sh /usr/bin/install-biojs
RUN chmod +x /usr/bin/install-repository /usr/bin/startup /usr/bin/install-biojs /usr/bin/add-tool-shed

# This needs to happen here and not above, otherwise the Galaxy start
# (without running the startup.sh script) will crash because integrated_tool_panel.xml could not be found.
ENV GALAXY_CONFIG_INTEGRATED_TOOL_PANEL_CONFIG /export/galaxy-central/integrated_tool_panel.xml

ADD ./cgroupfs_mount.sh /root/cgroupfs_mount.sh

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy), 9002 (supvisord web app)
EXPOSE :80
EXPOSE :21
EXPOSE :8800
EXPOSE :9002

# We need to set $HOME for some Tool Shed tools (e.g Perl libs with $HOME/.cpan)
ENV HOME $GALAXY_HOME
ENV PYTHONPATH /galaxy-central/lib/
# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
