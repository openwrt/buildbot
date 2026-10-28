FROM alpinelinux/build-base:latest-x86_64 AS apk-builder

RUN abuild-apk add -u \
	gcc \
	linux-headers \
	lua5.3-dev \
	lua5.3-lzlib \
	meson \
	musl-dev \
	ninja \
	openssl-dev \
	openssl-libs-static \
	patch \
	zlib-dev \
	zlib-static \
	zstd \
	zstd-dev \
	zstd-static

# apk-tools 3.0.5 is the version pinned in OpenWrt main and openwrt-25.12
ARG APK_TOOLS_VERSION=3.0.5
ARG APK_TOOLS_SHA256=bdb70571302d4baeafd4558522a49ce4c834c2acb51b954a19a3eea7f20b01b7
ARG APK_TOOLS_URL=https://sources.openwrt.org/apk-${APK_TOOLS_VERSION}.tar.zst

WORKDIR /tmp
RUN wget -O apk-tools.tar.zst "$APK_TOOLS_URL"
RUN echo "$APK_TOOLS_SHA256  apk-tools.tar.zst" | sha256sum -c - && \
	tar --zstd -xf apk-tools.tar.zst

WORKDIR /tmp/apk-${APK_TOOLS_VERSION}
COPY docker/buildmaster/patches /tmp/apk-patches
RUN for p in /tmp/apk-patches/*.patch; do patch -p1 < "$p" || exit 1; done
RUN VERSION=${APK_TOOLS_VERSION} meson setup build \
		--buildtype=release \
		-Db_lto=true \
		-Ddefault_library=static \
		-Dc_link_args=-static \
		-Dprefer_static=true \
		-Dcrypto_backend=openssl \
		-Durl_backend=libfetch \
		-Dhelp=enabled \
		-Dlua_version=5.3 \
		-Dlua=disabled \
		-Dpython=disabled \
		-Ddocs=disabled \
		-Dtests=disabled \
		-Dzstd=enabled && \
	meson compile -C build


FROM        debian:13
LABEL       maintainer="OpenWrt Maintainers"

ARG         DEBIAN_FRONTEND=noninteractive
ARG         BUILDBOT_VERSION=2.10.1
ARG         BUILDBOT_CONFIG_SHA=unknown

ENV         BUILDMASTER_CONFIG=config.ini
ENV         BUILDMASTER_PHASE=1

USER root

RUN \
	apt-get update && \
	apt-get install -y \
		build-essential \
		gawk \
		git-core \
		gnupg \
		gosu \
		libncurses-dev \
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
		legacy-cgi \
		pyOpenSSL \
		service_identity

RUN \
	sed -i \
	's/Welcome to buildbot/Welcome to OpenWrt buildbot/' \
	/opt/venv/lib/python*/site-packages/buildbot_www/static/scripts.js

RUN \
	sed -i \
	"s;\"col-sm-12\"><ul><li ng-repeat;\"col-sm-12\"><ul><li>OpenWrt buildbot config: <a href=\"https://git.openwrt.org/$BUILDBOT_CONFIG_SHA\">$BUILDBOT_CONFIG_SHA</a></li><li ng-repeat;" \
	/opt/venv/lib/python*/site-packages/buildbot_www/static/scripts.js

ENV LANG=en_US.utf8

COPY docker/buildmaster/files/entry.sh /entry.sh
COPY docker/buildmaster/files/start.sh /start.sh
COPY phase1 /phase1
COPY phase2 /phase2
COPY scripts /scripts
COPY --from=apk-builder /tmp/apk-3.0.5/build/src/apk /usr/bin/apk

RUN \
    groupadd buildbot && \
    useradd \
	--create-home --home-dir /master \
	--comment "OpenWrt buildbot" \
	--gid buildbot --shell /bin/bash buildbot && \
    chown buildbot:buildbot /master && \
    chmod 0755 /entry.sh /start.sh

RUN \
	mkdir -p /home/buildbot && \
	chmod u=rwx,go= /home/buildbot && \
	chown --recursive buildbot:buildbot /home/buildbot && \
	gosu buildbot sh -c "gpg --homedir /home/buildbot/.gnupg --recv-keys 0x1D53D1877742E911"

VOLUME [ "/master" ]
ENTRYPOINT [ "/entry.sh" ]
CMD [ "start" ]
