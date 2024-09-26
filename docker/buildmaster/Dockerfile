FROM alpinelinux/build-base:latest-x86_64 AS apk-builder

RUN abuild-apk add -u \
	gcc \
	git \
	linux-headers \
	lua5.3-dev \
	lua5.3-lzlib \
	make \
	musl-dev \
	openssl-dev \
	openssl-libs-static \
	zlib-dev \
	zlib-static \
	zstd-dev \
	zstd-static

ARG APK_TOOLS_COMMIT=74de0e9bd73d1af8720df40aa68d472943909804

RUN git clone https://gitlab.alpinelinux.org/alpine/apk-tools.git /tmp/apk-tools
WORKDIR /tmp/apk-tools
RUN git checkout $APK_TOOLS_COMMIT
RUN make -j$(nproc) static


FROM        debian:12
MAINTAINER  OpenWrt Maintainers

ARG         DEBIAN_FRONTEND=noninteractive
ARG         BUILDBOT_VERSION=2.10.1
ARG         OPENWRT_VERSION=unknown

ENV         BUILDMASTER_CONFIG config.ini
ENV         BUILDMASTER_PHASE  1

USER root

RUN \
	apt-get update && \
	apt-get install -y \
		build-essential \
		gawk \
		git-core \
		gosu \
		libncurses5-dev \
		locales \
		pv \
		pwgen \
		python3-venv \
		python3-pip \
		signify-openbsd \
		wget && \
	apt-get clean && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip3 install -U pip
RUN \
	pip3 install \
		"buildbot==$BUILDBOT_VERSION" \
		"buildbot-www==$BUILDBOT_VERSION" \
		"buildbot-waterfall-view==$BUILDBOT_VERSION" \
		"buildbot-console-view==$BUILDBOT_VERSION" \
		"buildbot-grid-view==$BUILDBOT_VERSION" \
		"buildbot-worker==$BUILDBOT_VERSION" \
		pyOpenSSL \
		service_identity

RUN \
	sed -i \
	's/Welcome to buildbot/Welcome to OpenWrt buildbot/' \
	/opt/venv/lib/python*/site-packages/buildbot_www/static/scripts.js

RUN \
	sed -i \
	"s;\"col-sm-12\"><ul><li ng-repeat;\"col-sm-12\"><ul><li>OpenWrt version: <a href=\"https://git.openwrt.org/$OPENWRT_VERSION\">$OPENWRT_VERSION</a></li><li ng-repeat;" \
	/opt/venv/lib/python*/site-packages/buildbot_www/static/scripts.js

ENV LANG=en_US.utf8

COPY docker/buildmaster/files/entry.sh /entry.sh
COPY docker/buildmaster/files/start.sh /start.sh
COPY phase1 /phase1
COPY phase2 /phase2
COPY scripts /scripts
COPY --from=apk-builder /tmp/apk-tools/src/apk.static /usr/bin/apk

RUN \
    groupadd buildbot && \
    useradd \
	--create-home --home-dir /master \
	--comment "OpenWrt buildbot" \
	--gid buildbot --shell /bin/bash buildbot && \
    chown buildbot:buildbot /master && \
    chmod 0755 /entry.sh /start.sh

VOLUME [ "/master" ]
ENTRYPOINT [ "/entry.sh" ]
CMD [ "start" ]
