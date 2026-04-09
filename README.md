# 0config

Home Manager configuration for Fedora Silverblue.

## Maintenance

Updating Fedora Silverblue packages:
```bash
rpm-ostree upgrade
systemctl reboot
```

Updating Nix:
```bash
nix flake update --flake ~/0config && home-manager switch --flake ~/0config
```

Garbage collecting Nix store:
```bash
nix-collect-garbage -d
```

## Setup

### 1. Initial setup
Connect to WiFi.

Use the Software application to apply any system updates.

Set up hostname and update any packages, then reboot.
```bash
hostnamectl set-hostname <name>
rpm-ostree upgrade
systemctl reboot
```

### 2. Install Nix and 0config

Needed for Nix to work on Silverblue.
- [Nix install guide on Silverblue](https://gist.github.com/queeup/1666bc0a5558464817494037d612f094)
- [transient root docs](https://ostreedev.github.io/ostree/man/ostree-prepare-root.html)

```bash
sudo tee /etc/ostree/prepare-root.conf <<'EOL'
[composefs]
enabled = yes
[root]
transient = true
EOL

rpm-ostree initramfs-etc --reboot --track=/etc/ostree/prepare-root.conf
systemctl reboot
```

Using the [nix-installer](https://github.com/NixOS/nix-installer).

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

Restart the shell, then set up home-manager with 0config
```bash
cd ~
git clone https://github.com/averagewagon/0config
nix-shell -p home-manager
home-manager switch --flake ~/0config -b backup
```

Flatpak apps (including Librewolf) and Syncthing are now installed and running.
- Librewolf - disable fingerprinting protections, turn on dark mode and sync, log in to sync
- Syncthing - accept new connection on other devices

### 3. Tailscale + RPM Fusion

Install Tailscale (networking) and RPM Fusion (proprietary Fedora packages) together to save a reboot.

```bash
sudo rpm-ostree install tailscale \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
systemctl reboot
```

Post-reboot, log in to Tailscale:
```bash
sudo systemctl enable --now tailscaled
sudo tailscale up
```

Add machine to Mullvad users on Tailscale, if desired. Optionally, enable ssh:
```bash
sudo tailscale up --ssh
```

### 4. SSH keys

```bash
ssh-keygen -t ed25519 -C "contact@joni.site" -f ~/.ssh/personal_key
cat ~/.ssh/personal_key.pub
```

Upload the public key to [github.com/settings/keys](https://github.com/settings/keys).

Switch the remote for 0config itself:
```bash
cd ~/0config
git remote set-url origin git@github.com:averagewagon/0config.git
```

### 5. Codecs

Replaces Fedora's patent-clean `ffmpeg-free` with the RPM Fusion build (H.264, AAC, etc.) and installs AMD VA-API for hardware video acceleration.

```bash
sudo rpm-ostree override remove \
  ffmpeg-free libavcodec-free libavfilter-free libavformat-free \
  libavutil-free libpostproc-free libswresample-free libswscale-free \
  libavdevice-free --install ffmpeg

sudo rpm-ostree install libva-utils
systemctl reboot
```

Post-reboot, verify it worked:

```bash
vainfo
ffmpeg -codecs 2>/dev/null | grep -E "h264|aac|hevc"
```

### 6. Miscellaneous
- Set dark mode in GNOME Settings
- Set default browser to Librewolf
- Bookmark Flatpak applications in the app launcher
- Add this machine to the Syncthing config, then re-run `home-manager switch` on other devices.

Note for Lenovo Yoga 7i - apply this to fix audio issues and reboot
```bash
echo "options snd-sof-intel-hda-generic hda_model=alc287-yoga9-bass-spk-pin" | sudo tee /etc/modprobe.d/yoga7i-audio.conf
systemctl reboot
```

Zed — Settings → Open Settings:

```json
{
  "agent": {
    "use_modifier_to_send": false,
    "play_sound_when_agent_done": true
  },
  "collaboration_panel": {
    "button": false
  },
  "agent_servers": {
    "claude-acp": {
      "type": "registry"
    }
  },
  "extend_comment_on_newline": false,
  "icon_theme": "Catppuccin Frappé",
  "theme": "Gruvbox Dark Hard",
  "buffer_font_features": {
    "calt": false
  },
  "lsp": {
    "rust-analyzer": {
      "initialization_options": {
        "cargo": {
          "features": "all"
        }
      }
    }
  }
}
```
