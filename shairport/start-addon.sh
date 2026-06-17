#!/bin/sh

CONFIG_PATH="/data/options.json"
TEMPLATE_PATH="/etc/shairport-sync.conf.tpl"
OUTPUT_PATH="/etc/shairport-sync.conf"

comment_out_setting() {
    setting="$1"
    sed -i "s/^[[:space:]]*${setting} =.*$/\/\/&/" "$OUTPUT_PATH"
}

if [ -f "$CONFIG_PATH" ]; then
    echo "Loading configuration from $CONFIG_PATH..."

    # Export JSON keys as environment variables
    eval $(jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""' "$CONFIG_PATH")

    echo "Environment variables exported."

    # Set defaults
    export mqtt_topic="${mqtt_topic:=airplay2}"
    export mqtt_publish_parsed="${mqtt_publish_parsed:=yes}"
    export mqtt_enable_remote="${mqtt_enable_remote:=no}"
    export mqtt_port="${mqtt_port:=1883}"
    export mqtt_publish_retain="${mqtt_publish_retain:=no}"
    export volume_max_db="${volume_max_db:=0.0}"
    export output_format="${output_format:=auto}"
    export output_rate="${output_rate:=auto}"
    export output_channels="${output_channels:=auto}"
    export output_device="${output_device:=default}"
    export use_precision_timing="${use_precision_timing:=auto}"
    export disable_standby_mode="${disable_standby_mode:=never}"
    export mixer_control_name="${mixer_control_name:=PCM}"
    export mixer_control_index="${mixer_control_index:=0}"
    export volume_control_combined_hardware_priority="${volume_control_combined_hardware_priority:=no}"
    export ignore_volume_control="${ignore_volume_control:=no}"
    export drift_tolerance_in_seconds="${drift_tolerance_in_seconds:=0.002}"
    export resync_threshold_in_seconds="${resync_threshold_in_seconds:=0.050}"
    export audio_backend_buffer_desired_length_in_seconds="${audio_backend_buffer_desired_length_in_seconds:=0.15}"
    export period_size="${period_size:=256}"
    export buffer_size="${buffer_size:=2048}"
    export session_timeout="${session_timeout:=60}"
    export log_verbosity="${log_verbosity:=0}"
    export playback_mode="${playback_mode:=stereo}"
    export volume_control_profile="${volume_control_profile:=standard}"
    export pulseaudio_server="${pulseaudio_server:=}"
    export pulseaudio_sink="${pulseaudio_sink:=}"
    export pulseaudio_application_name="${pulseaudio_application_name:=Shairport Sync}"

else
    echo "Error: $CONFIG_PATH not found."
    exit 1
fi

# Run envsubst to generate the final config file
if [ -f "$TEMPLATE_PATH" ]; then
    echo "Rendering $TEMPLATE_PATH -> $OUTPUT_PATH..."
    envsubst < "$TEMPLATE_PATH" > "$OUTPUT_PATH"

    if [ -z "$pulseaudio_server" ]; then
        comment_out_setting "server"
    fi
    if [ -z "$pulseaudio_sink" ]; then
        comment_out_setting "sink"
    fi

    echo "Success! Configuration generated."
else
    echo "Error: Template $TEMPLATE_PATH not found."
    exit 1
fi

echo "Removing syslogd from s6-overlay to prevent conflicts..."

# Löscht alle syslogd Verzeichnisse, falls sie existieren
if [ -d /etc/s6-overlay/s6-rc.d ] && ls /etc/s6-overlay/s6-rc.d/syslogd* >/dev/null 2>&1; then
    rm -rf /etc/s6-overlay/s6-rc.d/syslogd*
    echo "Syslogd service directories removed."
fi

# Löscht die Bundle-Referenz nur, wenn die Datei existiert
if [ -f /etc/s6-overlay/s6-rc.d/user/contents.d/syslogd-bundle ]; then
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/syslogd-bundle
    echo "Syslogd-bundle reference removed from user contents."
fi

exec ./run.sh
