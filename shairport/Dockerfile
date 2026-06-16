# syntax=docker/dockerfile:1
ARG BUILD_FROM
FROM mikebrady/shairport-sync:latest AS shairport

ARG BUILD_FROM
FROM ${BUILD_FROM}

# Libraries required by the Shairport Sync binary copied from the upstream image
RUN apk add --no-cache \
        alsa-lib \
        avahi-libs \
        ffmpeg-libs \
        libgcrypt \
        libplist \
        libuuid \
        libxml2 \
        openssl \
        soxr

COPY --from=shairport /usr/local/bin/shairport-sync /usr/local/bin/shairport-sync

COPY rootfs /
