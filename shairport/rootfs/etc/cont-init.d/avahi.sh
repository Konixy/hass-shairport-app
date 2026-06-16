#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Start D-Bus and Avahi before Shairport Sync registers its mDNS service.
# ==============================================================================

bashio::log.info "Setting up D-Bus and Avahi for mDNS advertisement..."

mkdir -p /run/dbus /run/avahi-daemon
rm -rf /run/dbus/dbus.pid /run/avahi-daemon/pid

dbus-uuidgen --ensure
dbus-daemon --system

avahi-daemon --daemonize --no-chroot

bashio::log.info "Avahi mDNS daemon started"
