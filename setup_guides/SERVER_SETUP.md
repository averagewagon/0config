# Server Setup

Steps to set up a new DigitalOcean Fedora droplet with 0config.

## 1. Create the droplet

Create a DigitalOcean droplet with Fedora as the OS. DigitalOcean requires an SSH key during setup — generate one and store it in Bitwarden. (You can skip using it and log into root through the DigitalOcean console instead.)

## 2. As root (from DigitalOcean console)

Create user with password (generate in Bitwarden):

```bash
useradd -m jhen
passwd jhen
usermod -aG wheel jhen
```

Install and enable Tailscale (with SSH auth):

```bash
sudo dnf install -y tailscale
sudo systemctl enable --now tailscaled
tailscale up --ssh
```

Install git:

```bash
sudo dnf install -y git
```

## 3. As jhen (via Tailscale SSH)

Reconnect to the droplet using Tailscale MagicDNS

```bash
ssh <hostname>
```

Set up an SSH key for this machine (see [SSH_KEYS.md](./credentials/SSH_KEYS.md)), then load it and clone 0config:

```bash
# Create a new BW login: ssh/<hostname>_personal_key
# Generate a password in Bitwarden for the new key
ssh-keygen -t ed25519 -C "contact@joni.site" -f ~/.ssh/personal_key
eval "$(ssh-agent -s)"
# Adding the key to the ssh-agent for 8 hours
ssh-add -t 8h ~/.ssh/personal_key
# store in BW item; upload to github.com/settings/keys
cat ~/.ssh/personal_key.pub
git clone git@github.com:hello-joni/0config.git
```

Install Nix:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

Set up external storage for Syncthing (if using an attached volume):

```bash
lsblk
sudo chown jhen:jhen /mnt/<volume-name>
mkdir /mnt/<volume-name>/0everything
ln -s /mnt/<volume-name>/0everything ~/0everything
```

Restart shell, then activate Home Manager:

```bash
nix-shell -p home-manager
home-manager switch --flake ~/0config#server
```

## 4. Syncthing

Access the server's Syncthing UI from your laptop:

```bash
ssh -L 8385:localhost:8384 jhen@<hostname>
```

Open `http://localhost:8385` and copy the new server's device ID. Add it to `syncthing.nix`, then re-run `home-manager switch` on all machines. Accept the new device on phone.

Wait for 0everything to sync, then server setup is complete.
