# syntax=docker/dockerfile:1
ARG BUILD_FROM
ARG SHAIRPORT_SYNC_VERSION=5.0.4
ARG NQPTP_VERSION=1.2.8

FROM ${BUILD_FROM} AS builder

ARG SHAIRPORT_SYNC_VERSION
ARG NQPTP_VERSION

RUN apk add --no-cache \
        alsa-lib-dev \
        autoconf \
        automake \
        avahi-dev \
        build-base \
        ffmpeg-dev \
        git \
        libconfig-dev \
        libgcrypt-dev \
        libplist-dev \
        libsndfile-dev \
        libsodium-dev \
        libtool \
        openssl-dev \
        pkgconf \
        popt-dev \
        soxr-dev \
        xxd

RUN git clone --depth=1 --branch "${NQPTP_VERSION}" https://github.com/mikebrady/nqptp.git /tmp/nqptp \
    && cd /tmp/nqptp \
    && autoreconf -fi \
    && ./configure \
    && make -j"$(nproc)" \
    && make install

RUN git clone --depth=1 --branch "${SHAIRPORT_SYNC_VERSION}" https://github.com/mikebrady/shairport-sync.git /tmp/shairport-sync \
    && cd /tmp/shairport-sync \
    && autoreconf -fi \
    && ./configure \
        --sysconfdir=/etc \
        --with-alsa \
        --with-soxr \
        --with-avahi \
        --with-ssl=openssl \
        --with-airplay-2 \
        --with-metadata \
    && make -j"$(nproc)" \
    && make install

FROM ${BUILD_FROM}

RUN apk add --no-cache \
        alsa-lib \
        avahi \
        avahi-libs \
        dbus \
        ffmpeg-libs \
        glib \
        libconfig \
        libcrypto3 \
        libgcrypt \
        libplist \
        libsndfile \
        libsodium \
        libuuid \
        libxml2 \
        openssl \
        popt \
        soxr

COPY --from=builder /usr/local/bin/shairport-sync /usr/local/bin/shairport-sync
COPY --from=builder /usr/local/bin/nqptp /usr/local/bin/nqptp

COPY rootfs /
