FROM ubuntu:18.04

LABEL maintainer="david@nedved.com.au"
LABEL description="A multi-container deployment of the Libretime Radio Broadcast Server, PostgreSQL, Icecast2 & RabbitMQ, based on Ubuntu Xenial & Alpine Linux!"

ENV LIBRETIME_TAG 3.0.0-alpha.8
ENV TZ Europe/Zurich

## General components we need in this container...

COPY pkgs_list.apt /pkgs_list.apt

RUN apt-get update && apt-get install --no-install-recommends -y apt-utils 
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get install --no-install-recommends -y $(cat /pkgs_list.apt)

## Locals need to be configured or the media monitor dies in the ass...
ENV PYTHONIOENCODING UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN locale-gen --purge en_US.UTF-8 && \
      update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

COPY systemctl.py /usr/bin/systemctl
RUN test -L /bin/systemctl || ln -sf /usr/bin/systemctl /bin/systemctl

# Pull down libretime sources
RUN export DEBIAN_FRONTEND=noninteractive && \
    git clone --branch $LIBRETIME_TAG --depth=1 https://github.com/LibreTime/libretime  /opt/libretime && \
    SYSTEM_INIT_METHOD=`readlink --canonicalize -n /proc/1/exe | rev | cut -d'/' -f 1 | rev` && \
    sed -i -e 's/\*systemd\*)/\*'"$SYSTEM_INIT_METHOD"'\*)/g' /opt/libretime/install && \
    echo "SYSTEM_INIT_METHOD: [$SYSTEM_INIT_METHOD]" && \
    #
    # We need to patch Liquidsoap for 1.3.x support (the current libretime builds only has 1.1.1 support)... 
    cd /opt/libretime && curl -L https://github.com/LibreTime/libretime/compare/master...radiorabe:feature/liquidsoap-1.3-for-3.0.0-alpha.7.patch | patch -p1 && \
        bash -c 'cd /opt/libretime; ./install --distribution=ubuntu --release=xenial_docker_minimal --force --apache --no-postgres --no-rabbitmq; exit 0'; exit 0

# This will be mapped in with all the media...
RUN mkdir -p /external-media/ && \
    chmod 777 /external-media/

# There seems to be a bug somewhere in the code and it's not respecting the DB being on another host (even though it's configured in the config files!)
# We'll use a lightweight golang TCP proxy to proxy any PGSQL request to the postgres docker container on TCP:5432. 

RUN cd /opt && curl -s -O -L https://dl.google.com/go/go1.10.1.linux-amd64.tar.gz && tar -xzf go* && \
    mv go /usr/local/ && \
    export GOPATH=/opt/ && \
    export GOROOT=/usr/local/go && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    go get github.com/jpillora/go-tcp-proxy/cmd/tcp-proxy && \
    rm -rf /opt/go1.*.tar.gz

# Remove PostgreSQL and RMQ other packages that were installed by the "Libretime Setup Script" -- before building Silian ...
RUN apt-get remove -y postgresql-9.5 rabbitmq-server icecast2 
#silan

RUN mkdir /liquidsoap && \
      cp /usr/local/lib/python2.7/dist-packages/airtime_playout-1.0-py2.7.egg/liquidsoap/* /liquidsoap

# We're going to install Liquidsoap 1.3.x directly from github (apt currently only has 1.1.1) -- this seems to have better stability overall with media stream.
# SEE: https://github.com/LibreTime/libretime/issues/192 - For further details around this.
RUN apt install cron
COPY bootstrap/entrypoint.sh bootstrap/add-to-cron.txt bootstrap/firstrun.sh /opt/libretime/
COPY config/supervisor-minimal.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /opt/libretime/firstrun.sh && \
    chmod +x /opt/libretime/entrypoint.sh && \
    #
    # Setup cron (the podcast script leaves a bit of a mess in /tmp - there's a few cleanup tasks that run via crontab)... 
    crontab /opt/libretime/add-to-cron.txt

# Cleanup excess fat...
RUN apt-get clean

VOLUME ["/etc/airtime", "/var/tmp/airtime/", "/var/log/airtime", "/usr/share/airtime", "/usr/lib/airtime"]
VOLUME ["/var/tmp/airtime"]
VOLUME ["/srv/airtime/watch", "/usr/local/lib/python2.7/dist-packages/airtime_playout-1.0-py2.7.egg/liquidsoap/"]

EXPOSE 80 8000

CMD ["/opt/libretime/entrypoint.sh"]
