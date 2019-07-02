FROM        debian:9
MAINTAINER  OpenWrt Maintainers

ARG         DEBIAN_FRONTEND=noninteractive

ENV         BUILDSLAVE_MASTER builds.openwrt.org:9990
ENV         BUILDSLAVE_ADMIN contact@openwrt.org
ENV         BUILDSLAVE_DESCRIPTION Buildslave Docker Instance

USER root

RUN apt-get update && \
    apt-get install -y \
	pwgen \
	locales \
	buildbot-slave \
	build-essential \
	git-core \
	subversion \
	libncurses5-dev \
	gawk \
	unzip \
	pv \
	gosu \
	signify-openbsd \
	python3 \
	wget \
	curl \
	ccache \
	rsync && \
    apt-get clean && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG=en_US.utf8

COPY docker/buildslave/files/entry.sh /entry.sh
COPY docker/buildslave/files/start.sh /start.sh

RUN mkdir /builder && \
    chown buildbot:buildbot /builder && \
    usermod --home /builder buildbot && \
    chmod 0755 /entry.sh /start.sh

VOLUME [ "/builder" ]
ENTRYPOINT [ "/entry.sh" ]
CMD [ "/start.sh" ]
