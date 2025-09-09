# macOS Port

This directory contains a macOS port of the based-connect tool, providing essential functionality for controlling Bose headphones on macOS systems.

## Overview

The macOS version is implemented in Objective-C (`based-connect.m`) and provides a subset of the original Linux functionality, focusing on core features that work reliably on macOS.

## Building

Simply run make in the macOS directory:

```bash
cd macOS
make
```

This will produce the `based-connect` executable.

## Usage

```bash
./based-connect [options] <address>
```

Where `address` is the Bluetooth address of your Bose device (e.g., `XX:XX:XX:XX:XX:XX`).

## Supported Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Print the help message |
| `-c <level>, --noise-cancelling=<level>` | Change noise cancelling level (`high`, `low`, `off`) |
| `-o <minutes>, --auto-off=<minutes>` | Change auto-off time (`never`, `5`, `20`, `40`, `60`, `180`) |
| `-f, --firmware-version` | Print the firmware version |
| `-s, --serial-number` | Print the serial number |
| `-b, --battery-level` | Print the battery level as a percentage |
| `-a, --paired-devices` | List connected devices (`!` = current device, `*` = other connected) |

## Platform Differences

The macOS port currently implements a subset of the original Linux functionality. Missing features include:

- Device name changes (`-n, --name`)
- Voice prompt language selection (`-l, --prompt-language`)
- Voice prompt on/off toggle (`-v, --voice-prompts`)
- Device status information (`-d, --device-status`)
- Pairing mode control (`-p, --pairing`)
- Device connection management (`--connect-device`, `--disconnect-device`, `--remove-device`)
- Device ID information (`--device-id`)

These features may be added in future updates as the macOS Bluetooth APIs and implementation are further developed.

## Requirements

- macOS with Bluetooth support
- Xcode command line tools (for compilation)

## Example

```bash
# Check battery level
./based-connect -b AA:BB:CC:DD:EE:FF

# Set noise cancelling to high
./based-connect -c high AA:BB:CC:DD:EE:FF

# Get firmware version
./based-connect -f AA:BB:CC:DD:EE:FF
```
