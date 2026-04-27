# Webserver Setup

Steps to set up a single-purpose webserver with 0config. Hosts the personal site at `joni.site`.
Works with any provider that offers Rocky Linux as a hosted image and accepts an SSH key at creation
time.

## 1. Create the server

In the cloud provider's dashboard, create a server with:

- OS: Rocky Linux (latest stable)
- SSH key: upload a public key from the machine you're currently on

Log in as root over the public IPv4 using the uploaded key.

## 2. As root

Set a fresh root password. Store it in the Proton Pass `machine-logins` vault as a Login item with
username `root@<hostname>` and a max-length generated password:

```bash
passwd root
```

Create the jhen user with its own password (same vault, username `jhen@<hostname>`, max-length
generated):

```bash
useradd -m -s /bin/bash jhen
passwd jhen
usermod -aG wheel jhen
```

Install and enable Tailscale (with SSH auth) using their official installer:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled
tailscale up --ssh
```

Install git:

```bash
dnf install -y git
```

Exit the root session.

## 3. As jhen (via Tailscale SSH)

Reconnect using Tailscale MagicDNS:

```bash
ssh <hostname>
```

Clone 0config:

```bash
git clone https://github.com/hello-joni/0config.git
```

Install Nix and source it for the current shell:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Activate Home Manager:

```bash
nix-shell -p home-manager
home-manager switch --flake ~/0config#webserver -b backup
```

## 4. DNS

From a machine with `dev.nix` activated, set the apex and `www` records for both IPv4 and IPv6 using
the `,dnsimple-set` helper:

```bash
export DNSIMPLE_TOKEN=...      # generate at DNSimple: Account -> Automation -> User access tokens
export DNSIMPLE_ACCOUNT_ID=... # numeric ID, visible in your DNSimple dashboard URL

,dnsimple-set joni.site ""  A    <ipv4>
,dnsimple-set joni.site ""  AAAA <ipv6>
,dnsimple-set joni.site www A    <ipv4>
,dnsimple-set joni.site www AAAA <ipv6>
```

`,dnsimple-set` is an idempotent upsert: it lists records of the given type only, filters by exact
name locally, and PATCHes if exactly one match exists or POSTs a new one. It refuses to act if
multiple matches exist. Records of any type other than the one you pass cannot be touched, so
existing MX/TXT/NS/SOA/CNAME records stay intact.

Wait for propagation before activating Caddy, otherwise the ACME challenge fails and Let's Encrypt
rate-limits retries. Verify with:

```bash
dig +short joni.site
dig +short AAAA joni.site
```

## 5. Install Caddy

Enable the official Caddy COPR repo and install:

```bash
sudo dnf install -y 'dnf-command(copr)'
sudo dnf copr enable -y @caddy/caddy
sudo dnf install -y caddy
```

This creates the `caddy` system user and the `caddy.service` systemd unit, which is what owns ports
80/443. Don't enable the service yet - it would start with the default Caddyfile.

## 6. Open the firewall

Rocky uses firewalld by default:

```bash
sudo firewall-cmd --permanent --add-service=http --add-service=https --add-port=443/udp
sudo firewall-cmd --reload
```

The `443/udp` port is for HTTP/3 (QUIC), which Caddy enables automatically. SSH is already in the
default zone, no need to add it.

## 7. Create the site directory

The site root lives under `jhen`'s home so static-site rsync deploys are easy:

```bash
mkdir -p ~/sites/joni.site
chmod 711 /home/jhen
chmod 755 ~/sites ~/sites/joni.site
```

The `chmod 711` on the home directory lets the `caddy` system user traverse into the home without
being able to list its contents. Files below should land as 644 (rsync defaults work).

Set the SELinux file context so the `caddy` process can read the site files:

```bash
sudo dnf install -y policycoreutils-python-utils
sudo semanage fcontext -a -t httpd_sys_content_t '/home/jhen/sites(/.*)?'
sudo restorecon -R /home/jhen/sites
```

This labels the site tree as web content for SELinux. New files created here (rsync, etc.) inherit
the label automatically.

## 8. Activate Home Manager

```bash
nix-shell -p home-manager
home-manager switch --flake ~/0config#webserver -b backup
```

This generates `~/.config/caddy/Caddyfile` from `modules/webserver.nix`.

## 9. Point the system Caddy at the generated config

```bash
sudo rm /etc/caddy/Caddyfile
sudo ln -s /home/jhen/.config/caddy/Caddyfile /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
```

Verify:

```bash
systemctl status caddy
curl -I https://joni.site
```

The first request triggers Caddy's ACME / Let's Encrypt flow and the cert lands automatically.

## 10. Deploy site content

From the build machine, rsync the static site output to `~/sites/joni.site/`:

```bash
rsync -av --delete ./public/ jhen@<hostname>:~/sites/joni.site/
```

Caddy serves the new files on the next request, no reload needed.
