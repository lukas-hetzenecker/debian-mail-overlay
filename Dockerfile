FROM debian:stretch-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_CORES

ARG SKALIBS_VER=2.6.3.1
ARG EXECLINE_VER=2.3.0.4
ARG S6_VER=2.7.0.0
ARG RSPAMD_VER=master
ARG GUCCI_VER=0.0.4

ARG SKALIBS_SHA256_HASH="8508ca00d4e2355e9ec0ec7f4808e98b349999d6732d2f123ac53b4df5260c81"
ARG EXECLINE_SHA256_HASH="e4bb8fc8f20cca96f4bac9f0f74ebce5081b4b687bb11c79c843faf12507a64b"
ARG S6_SHA256_HASH="6617cbf82c73273c67c6102a1a5c48449ef65ffbe8d0db6a587b7f0078dc6e13"
ARG RSPAMD_SHA256_HASH="3ae2064ae379adb575bb4f1edd05830a6643d362f22779947fccb18a51f8bfe2"
ARG GUCCI_SHA256_HASH="5b2c7cc7589ec760e30881e9bd4d806be0b8ecb71235ced5c190b5aaf88c46ae"

LABEL description="s6 + rspamd image based on Debian" \
      maintainer="Hardware <contact@meshup.net>" \
      rspamd_version="Rspamd v$RSPAMD_VER built from source" \
      s6_version="s6 v$S6_VER built from source"

ENV LC_ALL=C

RUN NB_CORES=${BUILD_CORES-$(getconf _NPROCESSORS_CONF)} \
    && BUILD_DEPS=" \
    cmake \
    gcc \
    make \
    ragel \
    wget \
    pkg-config \
    liblua5.1-0-dev \
    libglib2.0-dev \
    libevent-dev \
    libsqlite3-dev \
    libicu-dev \
    libssl-dev \
    libmagic-dev \
    libfann-dev" \
 && apt-get update && apt-get install -y -q --no-install-recommends \
    ${BUILD_DEPS} \
    libevent-2.0-5 \
    libglib2.0-0 \
    libssl1.1 \
    libmagic1 \
    liblua5.1-0 \
    libfann2 \
    libsqlite3-0 \
    sqlite3 \
    openssl \
    ca-certificates \
    gnupg \
    dirmngr \
 && cd /tmp \
 && SKALIBS_TARBALL="skalibs-${SKALIBS_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/skalibs/${SKALIBS_TARBALL} \
 && CHECKSUM=$(sha256sum ${SKALIBS_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${SKALIBS_SHA256_HASH}" ]; then echo "${SKALIBS_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${SKALIBS_TARBALL} && cd skalibs-${SKALIBS_VER} \
 && ./configure --prefix=/usr --datadir=/etc \
 && make && make install \
 && cd /tmp \
 && EXECLINE_TARBALL="execline-${EXECLINE_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/execline/${EXECLINE_TARBALL} \
 && CHECKSUM=$(sha256sum ${EXECLINE_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${EXECLINE_SHA256_HASH}" ]; then echo "${EXECLINE_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${EXECLINE_TARBALL} && cd execline-${EXECLINE_VER} \
 && ./configure --prefix=/usr \
 && make && make install \
 && cd /tmp \
 && S6_TARBALL="s6-${S6_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/s6/${S6_TARBALL} \
 && CHECKSUM=$(sha256sum ${S6_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${S6_SHA256_HASH}" ]; then echo "${S6_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${S6_TARBALL} && cd s6-${S6_VER} \
 && ./configure --prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin \
 && make && make install \
 && cd /tmp \
 && RSPAMD_TARBALL="${RSPAMD_VER}.tar.gz" \
 && wget -q https://github.com/vstakhov/rspamd/archive/${RSPAMD_TARBALL} \
 && CHECKSUM=$(sha256sum ${RSPAMD_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${RSPAMD_SHA256_HASH}" ]; then echo "${RSPAMD_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${RSPAMD_TARBALL} && cd rspamd-${RSPAMD_VER} \
 && cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCONFDIR=/etc/rspamd \
    -DRUNDIR=/run/rspamd \
    -DDBDIR=/var/mail/rspamd \
    -DLOGDIR=/var/log/rspamd \
    -DPLUGINSDIR=/usr/share/rspamd \
    -DLIBDIR=/usr/lib/rspamd \
    -DNO_SHARED=ON \
    -DWANT_SYSTEMD_UNITS=OFF \
    . \
 && make -j${NB_CORES} \
 && make install \
 && cd /tmp \
 && GUCCI_BINARY="gucci-v${GUCCI_VER}-linux-amd64" \
 && wget -q https://github.com/noqcks/gucci/releases/download/v${GUCCI_VER}/${GUCCI_BINARY} \
 && CHECKSUM=$(sha256sum ${GUCCI_BINARY} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${GUCCI_SHA256_HASH}" ]; then echo "${GUCCI_BINARY} : bad checksum" && exit 1; fi \
 && chmod +x ${GUCCI_BINARY} \
 && mv ${GUCCI_BINARY} /usr/local/bin/gucci \
 && apt-get purge -y ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old
