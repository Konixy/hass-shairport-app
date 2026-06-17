#!/bin/sh

CONFIG_PATH="/data/options.json"
TEMPLATE_PATH="/etc/shairport-sync.conf.tpl"
OUTPUT_PATH="/etc/shairport-sync.conf"

set_config_value() {
    section="$1"
    key="$2"
    value="$3"
    type="$4"

    case "$type" in
        string) formatted="\"${value}\"" ;;
        *) formatted="$value" ;;
    esac

    awk -v section="$section" -v key="$key" -v val="$formatted" '
    BEGIN { in_section=0 }
    /^[a-z]+ =$/ {
        sec=$1
        sub(/ =$/, "", sec)
        in_section=(sec==section)
    }
    in_section && match($0, "^[[:space:]]*(//[[:space:]]*)?" key " =") {
        comment=""
        if (match($0, /;[[:space:]]*\/\/.*/)) {
            comment=substr($0, RSTART)
        }
        print "\t" key " = " val comment
        next
    }
    { print }
    ' "$OUTPUT_PATH" > "${OUTPUT_PATH}.tmp" && mv "${OUTPUT_PATH}.tmp" "$OUTPUT_PATH"
}

apply_if_changed() {
    option="$1"
    section="$2"
    key="$3"
    type="$4"
    default="$5"

    eval "value=\${$option:-}"

    if [ -z "$value" ]; then
        case "$key" in
            mixer_control_name|pulseaudio_server|pulseaudio_sink|mqtt_topic) return 0 ;;
        esac
    fi

    if [ "$key" = "period_size" ] || [ "$key" = "buffer_size" ]; then
        [ "$value" = "0" ] && return 0
    fi

    if [ "$key" = "name" ] && [ "$value" = "%H" ]; then
        return 0
    fi

    if [ "$value" = "$default" ]; then
        return 0
    fi

    set_config_value "$section" "$key" "$value" "$type"
}

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Error: $CONFIG_PATH not found."
    exit 1
fi

echo "Loading configuration from $CONFIG_PATH..."
eval $(jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""' "$CONFIG_PATH")

# Addon option defaults (aligned with upstream shairport-sync.conf commented defaults)
export airplay_name="${airplay_name:-Home Assistant}"
export interpolation="${interpolation:-auto}"
export output_backend="${output_backend:-alsa}"
export offset="${offset:-0.0}"
export drift_tolerance_in_seconds="${drift_tolerance_in_seconds:-0.002}"
export resync_threshold_in_seconds="${resync_threshold_in_seconds:-0.050}"
export default_airplay_volume="${default_airplay_volume:--24.0}"
export volume_max_db="${volume_max_db:-0.0}"
export volume_control_combined_hardware_priority="${volume_control_combined_hardware_priority:-no}"
export ignore_volume_control="${ignore_volume_control:-no}"
export playback_mode="${playback_mode:-stereo}"
export volume_control_profile="${volume_control_profile:-standard}"
export output_device="${output_device:-default}"
export mixer_control_name="${mixer_control_name:-}"
export mixer_control_index="${mixer_control_index:-0}"
export output_rate="${output_rate:-auto}"
export output_format="${output_format:-auto}"
export output_channels="${output_channels:-auto}"
export use_precision_timing="${use_precision_timing:-auto}"
export disable_standby_mode="${disable_standby_mode:-never}"
export audio_backend_buffer_desired_length_in_seconds="${audio_backend_buffer_desired_length_in_seconds:-0.2}"
export period_size="${period_size:-0}"
export buffer_size="${buffer_size:-0}"
export enabled="${enabled:-no}"
export mqtt_host="${mqtt_host:-core-mosquitto}"
export mqtt_port="${mqtt_port:-1883}"
export mqtt_username="${mqtt_username:-}"
export mqtt_password="${mqtt_password:-}"
export mqtt_topic="${mqtt_topic:-shairport}"
export mqtt_publish_parsed="${mqtt_publish_parsed:-yes}"
export mqtt_publish_cover="${mqtt_publish_cover:-no}"
export mqtt_publish_retain="${mqtt_publish_retain:-no}"
export mqtt_enable_remote="${mqtt_enable_remote:-no}"
export session_timeout="${session_timeout:-60}"
export log_verbosity="${log_verbosity:-0}"
export pulseaudio_server="${pulseaudio_server:-}"
export pulseaudio_sink="${pulseaudio_sink:-}"
export pulseaudio_application_name="${pulseaudio_application_name:-Shairport Sync}"

if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Error: Template $TEMPLATE_PATH not found."
    exit 1
fi

echo "Rendering $TEMPLATE_PATH -> $OUTPUT_PATH..."
cp "$TEMPLATE_PATH" "$OUTPUT_PATH"

apply_if_changed airplay_name general name string "Home Assistant"
apply_if_changed interpolation general interpolation string "auto"
apply_if_changed output_backend general output_backend string "alsa"
apply_if_changed offset general audio_backend_latency_offset_in_seconds float "0.0"
apply_if_changed drift_tolerance_in_seconds general drift_tolerance_in_seconds float "0.002"
apply_if_changed resync_threshold_in_seconds general resync_threshold_in_seconds float "0.050"
apply_if_changed playback_mode general playback_mode string "stereo"
apply_if_changed ignore_volume_control general ignore_volume_control string "no"
apply_if_changed volume_max_db general volume_max_db float "0.0"
apply_if_changed volume_control_profile general volume_control_profile string "standard"
apply_if_changed volume_control_combined_hardware_priority general volume_control_combined_hardware_priority string "no"
apply_if_changed default_airplay_volume general default_airplay_volume float "-24.0"
apply_if_changed audio_backend_buffer_desired_length_in_seconds general audio_backend_buffer_desired_length_in_seconds float "0.2"
apply_if_changed session_timeout sessioncontrol session_timeout int "60"

apply_if_changed output_device alsa output_device string "default"
apply_if_changed mixer_control_name alsa mixer_control_name string ""
apply_if_changed mixer_control_index alsa mixer_control_index int "0"
apply_if_changed output_rate alsa output_rate string "auto"
apply_if_changed output_format alsa output_format string "auto"
apply_if_changed output_channels alsa output_channels string "auto"
apply_if_changed period_size alsa period_size int "0"
apply_if_changed buffer_size alsa buffer_size int "0"
apply_if_changed use_precision_timing alsa use_precision_timing string "auto"
apply_if_changed disable_standby_mode alsa disable_standby_mode string "never"

if [ "$output_backend" = "pulseaudio" ] || [ "$output_backend" = "pa" ]; then
    apply_if_changed pulseaudio_server pulseaudio server string ""
    apply_if_changed pulseaudio_sink pulseaudio sink string ""
    apply_if_changed pulseaudio_application_name pulseaudio application_name string "Shairport Sync"
fi

if [ "$enabled" = "yes" ]; then
    set_config_value mqtt enabled "yes" string
    apply_if_changed mqtt_host mqtt hostname string "iot.eclipse.org"
    apply_if_changed mqtt_port mqtt port int "1883"
    [ -n "$mqtt_username" ] && set_config_value mqtt username "$mqtt_username" string
    [ -n "$mqtt_password" ] && set_config_value mqtt password "$mqtt_password" string
    [ -n "$mqtt_topic" ] && set_config_value mqtt topic "$mqtt_topic" string
    apply_if_changed mqtt_publish_parsed mqtt publish_parsed string "yes"
    apply_if_changed mqtt_publish_cover mqtt publish_cover string "no"
    apply_if_changed mqtt_publish_retain mqtt publish_retain string "no"
    apply_if_changed mqtt_enable_remote mqtt enable_remote string "no"
fi

apply_if_changed log_verbosity diagnostics log_verbosity int "0"

echo "Success! Configuration generated."

echo "Removing syslogd from s6-overlay to prevent conflicts..."

if [ -d /etc/s6-overlay/s6-rc.d ] && ls /etc/s6-overlay/s6-rc.d/syslogd* >/dev/null 2>&1; then
    rm -rf /etc/s6-overlay/s6-rc.d/syslogd*
    echo "Syslogd service directories removed."
fi

if [ -f /etc/s6-overlay/s6-rc.d/user/contents.d/syslogd-bundle ]; then
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/syslogd-bundle
    echo "Syslogd-bundle reference removed from user contents."
fi

exec /run-addon.sh
