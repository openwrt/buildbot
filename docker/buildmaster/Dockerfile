FROM        debian:10
MAINTAINER  OpenWrt Maintainers

ARG         DEBIAN_FRONTEND=noninteractive

ENV         BUILDMASTER_CONFIG config.ini
ENV         BUILDMASTER_PHASE  1

USER root

RUN apt-get update && \
    apt-get install -y \
	pwgen \
	locales \
	buildbot \
	build-essential \
	libncurses5-dev \
	gawk \
	git-core \
	pv \
	gosu \
	signify-openbsd \
	python3-pip \
	wget && \
    apt-get clean && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    pip3 install \
	"buildbot-www==2.0.1" \
	"buildbot-waterfall-view==2.0.1" \
	"buildbot-console-view==2.0.1" \
	"buildbot-grid-view==2.0.1"

ENV LANG=en_US.utf8

COPY docker/buildmaster/files/entry.sh /entry.sh
COPY docker/buildmaster/files/start.sh /start.sh
COPY phase1 /phase1
COPY phase2 /phase2
COPY scripts /scripts

RUN mkdir /master && \
    chown buildbot:buildbot /master && \
    usermod --home /master buildbot && \
    chmod 0755 /entry.sh /start.sh

VOLUME [ "/master" ]
ENTRYPOINT [ "/entry.sh" ]
CMD [ "start" ]
