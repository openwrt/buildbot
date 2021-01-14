FROM        debian:10
MAINTAINER  OpenWrt Maintainers

ARG         DEBIAN_FRONTEND=noninteractive
ARG         BUILDBOT_VERSION=2.10.1

ENV         BUILDSLAVE_MASTER builds.openwrt.org:9990
ENV         BUILDSLAVE_ADMIN contact@openwrt.org
ENV         BUILDSLAVE_DESCRIPTION Buildslave Docker Instance

USER root

RUN \
	apt-get update && \
	apt-get install -y \
		build-essential \
		ccache \
		curl \
		gawk \
		git-core \
		gosu \
		libncurses5-dev \
		locales \
		rsync \
		signify-openbsd \
		subversion \
		pv \
		pwgen \
		python3 \
		python3-pip \
		qemu-utils \
		unzip \
		wget && \
	apt-get clean && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN pip3 install \
		"buildbot-worker==$BUILDBOT_VERSION" \
		pyOpenSSL \
		service_identity

ENV LANG=en_US.utf8

COPY docker/buildslave/files/entry.sh /entry.sh
COPY docker/buildslave/files/start.sh /start.sh

RUN \
    groupadd buildbot && \
    useradd \
	--create-home --home-dir /builder \
	--comment "OpenWrt buildbot" \
	--gid buildbot --shell /bin/bash buildbot && \
    chown buildbot:buildbot /builder && \
    chmod 0755 /entry.sh /start.sh

VOLUME [ "/builder" ]
ENTRYPOINT [ "/entry.sh" ]
CMD [ "/start.sh" ]
