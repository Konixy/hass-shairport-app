# syntax=docker/dockerfile:1
FROM mikebrady/shairport-sync:5.0.4 AS shairport

ARG BUILD_FROM
FROM ${BUILD_FROM}

# Runtime libraries required by the Shairport Sync binary
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
        libpulse \
        libsndfile \
        libuuid \
        libxml2 \
        openssl \
        popt \
        soxr

COPY --from=shairport /usr/local/bin/shairport-sync /usr/local/bin/shairport-sync
COPY --from=shairport /usr/local/lib/ /usr/local/lib/

COPY rootfs /
