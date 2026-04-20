# Laptop Setup

Steps to set up a personal Fedora Silverblue laptop with 0config.

## 1. Initial setup

Connect to WiFi.

Use the Software application to apply any system updates.

Set up hostname and update any packages, then reboot.

```bash
hostnamectl set-hostname <name>
rpm-ostree upgrade
systemctl reboot
```

## 2. Install Nix and 0config

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

Restart the shell, then clone and activate 0config:

```bash
cd ~

git clone https://github.com/hello-joni/0config.git
nix-shell -p home-manager
home-manager switch --flake ~/0config#laptop -b backup
```

Flatpak apps (including Librewolf) and Syncthing are now installed and running.

- Librewolf - disable fingerprinting protections, turn on dark mode and sync, log in to sync
- Syncthing - accept new connection on other devices

## 3. SSH keys

Set up an SSH key for this machine (see [SSH_KEYS.md](./credentials/SSH_KEYS.md)), then load it and clone 0config:

```bash
# Create a new BW login: ssh/<hostname>_personal_key
# Generate a password in Bitwarden for the new key
ssh-keygen -t ed25519 -C "contact@joni.site" -f ~/.ssh/personal_key
ssh-add -t 8h ~/.ssh/personal_key
# store in BW item; upload to github.com/settings/keys
cat ~/.ssh/personal_key.pub
```

## 4. Tailscale + RPM Fusion

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

## 5. Codecs

Enables H.264/H.265 hardware decode. Follow the guide for your GPU vendor:

- AMD: [hardware/AMD_GPU_CODECS.md](./hardware/AMD_GPU_CODECS.md)
- Intel: [hardware/INTEL_GPU_CODECS.md](./hardware/INTEL_GPU_CODECS.md)

## 6. Syncthing

Open the Syncthing UI at `http://localhost:8384` and copy the new laptop's device ID. Add it to `syncthing.nix`, then re-run `home-manager switch` on all machines. Accept the new device on phone.

Wait for 0everything to sync.

## 7. Zram

If the machine has more than 16GB RAM, raise Fedora's default zram cap. See [hardware/ZRAM.md](./hardware/ZRAM.md).

## 8. Miscellaneous

Set profile picture:

```bash
sudo cp /var/home/jhen/0everything/0media/images/profile-pics/cartoonwagon.jpg /var/lib/AccountsService/icons/jhen
sudo systemctl restart accounts-daemon
```

For device-specific quirks (audio fixes, etc.), see the [hardware/](./hardware/) folder.
