#!/bin/sh

set -e

echo "Shairport Sync Startup ($(date))"

if [ -z ${ENABLE_AVAHI+x} ] || [ "$ENABLE_AVAHI" = "1" ]; then
    rm -rf /run/dbus/dbus.pid
    rm -rf /run/avahi-daemon/pid

    dbus-uuidgen --ensure
    dbus-daemon --system

    avahi-daemon --daemonize --no-chroot
fi

echo "Starting NQPTP ($(date))"

(/usr/local/bin/nqptp > /dev/null 2>&1) &

while [ ! -f /var/run/avahi-daemon/pid ]; do
    echo "Warning: avahi is not running, sleeping for 5 seconds before trying to start shairport-sync"
    sleep 5
done

export XDG_RUNTIME_DIR=/tmp

# Upstream docker run.sh targets standalone Docker (unix:/tmp/pulseaudio.socket).
# Home Assistant add-ons with audio: true mount PulseAudio at /run/audio instead.
if [ -S /run/audio/pulse.sock ]; then
    unset PULSE_SERVER
    unset PULSE_COOKIE
    echo "Using Home Assistant audio at unix:/run/audio/pulse.sock."
else
    export PULSE_SERVER="${PULSE_SERVER:-unix:/tmp/pulseaudio.socket}"
    export PULSE_COOKIE="${PULSE_COOKIE:-/tmp/pulseaudio.cookie}"
fi

echo "Finished startup tasks ($(date)), starting Shairport Sync."

exec /usr/local/bin/shairport-sync "$@"
