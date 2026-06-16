# Shairport Sync

Turn your Home Assistant host into an **AirPlay 2** receiver using [Shairport Sync](https://github.com/mikebrady/shairport-sync). Stream audio from iPhone, iPad, Mac, or Apple TV to speakers connected to your Home Assistant device.

This add-on is tuned for **Home Assistant OS on Raspberry Pi** and similar hardware: low latency (~150 ms), no DAC standby pops, and reliable audio output over aggressive clock sync.

## Features

- **AirPlay 2** — appears as a native AirPlay target on your Apple devices
- **ALSA output** — direct hardware access for USB DACs and HAT sound cards
- **Tunable buffers** — reduce the default ~5 s latency without dropouts
- **Standby control** — prevent DAC click/pop noise between sessions
- **Sensible defaults** — works out of the box on most Pi + USB/HAT setups

## Installation

1. Add this repository in the Home Assistant **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Install **Shairport Sync**.
3. Configure options below (defaults are fine for a first test).
4. Start the add-on and select it as an AirPlay output on your Apple device.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | `"Home Assistant"` | Name shown in the AirPlay picker on Apple devices (max 50 characters). |
| `output_device` | string | `"default"` | ALSA output device. Use `default`, `hw:0`, `hw:1,0`, or a named device from `aplay -L`. |
| `mixer_control_name` | string? | *(empty)* | Hardware mixer control (e.g. `PCM`, `Digital`, `Headphone`). Leave empty for software volume only. |
| `output_rate` | int | `44100` | Fixed output sample rate in Hz. Most DACs support 44100; some prefer 48000. |
| `output_format` | string | `"S16_LE"` | Sample format: `S16_LE`, `S24_LE`, or `S32_LE`. Use `S16_LE` unless your DAC supports higher bit depths. |
| `buffer_length_seconds` | float | `0.15` | Backend buffer length (0.05–1.0 s). Lower = less latency; too low causes dropouts on slow hardware. |
| `period_size` | int | `256` | ALSA period size (64–4096). Smaller values reduce latency but increase CPU load. |
| `buffer_size` | int | `2048` | ALSA buffer size (512–16384). Must be larger than `period_size`. |
| `disable_standby_mode` | string | `"auto"` | Prevent DAC standby: `always`, `auto` (while playing), or `never`. Use `auto` to stop standby pop/click noise. |
| `use_precision_timing` | bool | `false` | Enable ALSA precision timing. Can fix sync on some DACs but often causes **silent playback** — leave off unless you know you need it. |
| `interpolation` | string | `"basic"` | Sync interpolation: `basic`, `soxr`, or `auto`. `basic` is most reliable on Pi hardware; `soxr` needs a fast CPU. |
| `drift_tolerance_seconds` | float | `0.001` | Clock drift tolerance before correction (0.0001–0.01 s). Higher values are more tolerant of unstable clocks. |
| `ignore_volume_control` | bool | `false` | Force 100% output volume regardless of the AirPlay source volume slider. |
| `log_verbosity` | int | `0` | Debug log level 0–3. Use `2` or `3` when troubleshooting; higher values are very verbose. |

### Finding your ALSA device

On the Home Assistant host terminal:

```bash
ha audio info
aplay -L
```

Common values:

- Built-in / default routing: `default`
- First sound card: `hw:0`
- USB DAC (often second card): `hw:1,0`

## Example configurations

### HiFiBerry DAC+ / DAC+ Pro (HAT)

```yaml
name: "Living Room"
output_device: "hw:0"
mixer_control_name: "Digital"
output_rate: 44100
output_format: "S24_LE"
buffer_length_seconds: 0.15
disable_standby_mode: "auto"
use_precision_timing: false
interpolation: "basic"
```

### IQaudIO DAC+ / DAC Pro

```yaml
name: "Kitchen"
output_device: "hw:0"
mixer_control_name: "PCM"
output_rate: 44100
output_format: "S16_LE"
buffer_length_seconds: 0.15
period_size: 256
buffer_size: 2048
disable_standby_mode: "auto"
```

### USB DAC (e.g. Schiit, Topping, Fiio)

```yaml
name: "Office Speakers"
output_device: "hw:1,0"
mixer_control_name: "PCM"
output_rate: 44100
output_format: "S16_LE"
buffer_length_seconds: 0.2
disable_standby_mode: "always"
use_precision_timing: false
```

If your USB DAC is the only audio device, try `hw:0,0` instead of `hw:1,0`.

## Troubleshooting

### Constant low-level noise or pop/click between tracks

- Set **`disable_standby_mode`** to `auto` or `always`.
- Try **`ignore_volume_control`**: `true` if volume changes cause noise on your DAC.
- Avoid **`use_hardware_mute_if_available`** (hardcoded off in this add-on for compatibility).

### ~5 second latency

- Lower **`buffer_length_seconds`** to `0.15` (default) or `0.10`.
- Reduce **`period_size`** (e.g. `256`) and **`buffer_size`** (e.g. `2048`) together.
- Do not go below `0.05` s buffer unless you accept occasional dropouts.

### Connection succeeds but no audio

This is usually a timing or format mismatch:

1. Set **`use_precision_timing`** to `false` (default).
2. Set **`interpolation`** to `basic`.
3. Fix **`output_rate`** and **`output_format`** to values your DAC actually supports (`S16_LE` @ `44100` is the safest).
4. Verify **`output_device`** with `aplay -L` on the host.
5. Raise **`drift_tolerance_seconds`** slightly (e.g. `0.002`).
6. Enable **`log_verbosity`**: `2` and inspect add-on logs after connecting.

### Audio dropouts / stuttering

- Increase **`buffer_length_seconds`** to `0.2`–`0.35`.
- Increase **`buffer_size`** (e.g. `4096`).
- Keep **`interpolation`** on `basic` on Raspberry Pi.

### Device not visible on the network

- Ensure **`host_network`** is enabled (default for this add-on).
- Confirm mDNS/AirPlay is not blocked by VLAN or firewall rules.
- Restart the add-on after changing network settings.

## Technical notes

- Built from [mikebrady/shairport-sync](https://github.com/mikebrady/shairport-sync) 4.3.7 with AirPlay 2 support.
- Configuration is rendered at startup from add-on options via **bashio** and **tempio**.
- AirPlay 2 listens on port **7000**.
- ALSA **`use_mmap_if_available`** is forced to `no` for stability on embedded hardware.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
