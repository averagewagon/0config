# Server Setup

Steps to set up a new cloud server with 0config. Works with any provider that offers Fedora as a
hosted image and accepts an SSH key at creation time. Currently using Hetzner and DigitalOcean.

## 1. Create the server

In the cloud provider's dashboard, create a server with:

- **OS**: Fedora
- **SSH key**: upload a public key from the machine you're currently on (Tailscale handles SSH after
  this, so it's just for the initial login)
- **Volume** (optional): for persistent `~/0everything` storage
- **Backups** (optional): worth enabling once the server holds anything unique

Log in as root over the public IPv4 using the uploaded key.

## 2. As root

Set a fresh root password. Store it in the Proton Pass `machine-logins` vault as a Login item with
username `root@<hostname>` and a max-length generated password:

```bash
sudo passwd root
```

Create the jhen user with its own password (same vault, username `jhen@<hostname>`, max-length
generated):

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

Exit the root session.

## 3. As jhen (via Tailscale SSH)

Reconnect using Tailscale MagicDNS:

```bash
ssh <hostname>
```

Set up an SSH key for this machine (see [SSH_KEYS.md](./credentials/SSH_KEYS.md)), then clone
0config:

```bash
git clone git@github.com:hello-joni/0config.git
```

Install Nix and source it for the current shell:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Set up external storage for Syncthing (if using an attached volume):

```bash
lsblk
sudo chown jhen:jhen /mnt/<volume-name>
mkdir /mnt/<volume-name>/0everything
ln -s /mnt/<volume-name>/0everything ~/0everything
```

Activate Home Manager:

```bash
nix-shell -p home-manager
home-manager switch --flake ~/0config#server -b backup
```

## 4. Syncthing

Access the server's Syncthing UI from your laptop:

```bash
ssh -L 8385:localhost:8384 jhen@<hostname>
```

Open `http://localhost:8385` and copy the new server's device ID. Add it to `syncthing.nix`, then
re-run `home-manager switch` on all machines. Accept the new device on phone.

Wait for 0everything to sync, then server setup is complete.
