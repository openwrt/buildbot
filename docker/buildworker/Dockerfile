FROM        debian:10
MAINTAINER  OpenWrt Maintainers

ARG         DEBIAN_FRONTEND=noninteractive
ARG         BUILDBOT_VERSION=2.10.1

ENV         BUILDWORKER_MASTER builds.openwrt.org:9990
ENV         BUILDWORKER_ADMIN contact@openwrt.org
ENV         BUILDWORKER_DESCRIPTION Buildworker Docker Instance

USER root

RUN \
	apt-get update && \
	apt-get install -y \
		build-essential \
		ccache \
		curl \
		gawk \
		gcc-multilib \
		git-core \
		gosu \
		libncurses5-dev \
		locales \
		rsync \
		signify-openbsd \
		subversion \
		swig \
		pv \
		pwgen \
		python3 \
		python3-pip \
		qemu-utils \
		unzip \
		wget && \
	apt-get clean && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN pip3 install -U pip
RUN pip3 install \
		"buildbot-worker==$BUILDBOT_VERSION" \
		pyOpenSSL \
		service_identity

ENV LANG=en_US.utf8

COPY docker/buildworker/files/entry.sh /entry.sh
COPY docker/buildworker/files/start.sh /start.sh

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
