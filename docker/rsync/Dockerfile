FROM debian:12

COPY docker/rsync/files/entry.sh /entry.sh

RUN apt-get update && \
    apt-get -y install rsync && \
    apt-get clean && \
    mkdir -p /data && \
    chmod 0755 /entry.sh

EXPOSE 873
VOLUME [ "/data" ]
ENTRYPOINT [ "/entry.sh" ]
HEALTHCHECK CMD xargs kill -0 < /tmp/rsyncd.pid
