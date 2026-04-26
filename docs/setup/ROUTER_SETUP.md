# Router Setup

Steps to set up an OpenWRT One router after a firmware update.

## 1. Initial setup

Using the LuCI webpage, Update OpenWRT One firmware and factory reset settings.

Connect to the router via Ethernet and open LuCI at `http://192.168.1.1`. Set the root password
(generate in Proton Pass).

## 2. Wireless

Navigate to Network → Wireless and configure both radios:

**2.4 GHz:** - Used for IoT devices and things with low bandwidth necessity

- Encryption: mixed WPA2/WPA3 PSK, SAE (CCMP)
- Set ESSID, Key, and Country Code to `US`

**5 GHz:** - Used for phones and laptops and such, so tighter security

- Encryption: WPA3 SAE (CCMP)
- Set ESSID, Key, and Country Code to `US`

## 3. Install Git and track config

```bash
apk update
apk add git
git config --global init.defaultBranch main
git config --global user.name "Joni Hendrickson"
git config --global user.email contact@joni.site
git config --global color.ui false
```

Create a repo in `/etc/config` to track changes:

```bash
cd /etc/config
git init
git add .
git commit -m "Fresh factory baseline with 2.4GHz and 5GHz"
```

## 4. Smart Queue Management (SQM)

SQM uses the `cake` queueing discipline to defeat bufferbloat.

Install the package:

```bash
apk add luci-app-sqm
```

Enable packet steering:

- LuCI → Network → Interfaces → Global network options → enable **Packet Steering (all CPUs)**

Run a speed test at [waveform.com/tools/bufferbloat](https://www.waveform.com/tools/bufferbloat) and
note your download/upload speeds. Multiply each by 0.9 and convert to kbit/s — these are your SQM
targets.

Log out and back into LuCI, then navigate to Network → SQM QoS:

### Basic Settings

- Enable: checked
- Interface: `eth0` (WAN)
- Download / Upload speed: 90% of baseline results (in kbit/s)

### Queue Discipline:

- Queueing Discipline: `cake`
- Queue Setup Script: `piece_of_cake.qos`

### Link Layer Adaptation (for fiber/ethernet):

- Link Layer Type: `Ethernet`
- Per Packet Overhead: `44` bytes
- Enable Advanced Linklayer Options
- Minimum packet size: `84`
