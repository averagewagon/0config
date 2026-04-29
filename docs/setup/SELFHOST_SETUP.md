# Selfhost Setup

Steps to layer self-hosted services onto a server already provisioned per
[SERVER_SETUP.md](./SERVER_SETUP.md). Currently hosts Actual Budget. Access is Tailscale-only via
`tailscale serve` with automatic HTTPS.

## 1. Prerequisites

A Rocky Linux server with the `server` profile already activated (Tailscale up, Syncthing running,
0everything synced). The `selfhost` profile is a superset of `server`, so the same machine just
swaps profiles.

## 2. Enable user lingering

User systemd services need lingering enabled to start at boot without a login session:

```bash
sudo loginctl enable-linger jhen
```

## 3. Switch to the selfhost profile

```bash
home-manager switch --flake ~/0config#selfhost -b backup
```

This installs Podman quadlets for each container declared in `modules/selfhost.nix` and starts them
as user systemd services. Verify:

```bash
systemctl --user status podman-actual.service
```

The Actual server now listens on `127.0.0.1:5006` inside the host. It is not reachable from the
public internet.

## 4. Expose via Tailscale Serve

Bind the container to the host's tailnet name with automatic HTTPS:

```bash
tailscale serve --bg --https=443 http://localhost:5006
```

Verify:

```bash
tailscale serve status
```

Actual is now reachable at `https://<hostname>.<tailnet>.ts.net` from any device on the tailnet,
including the phone. The `tailscale serve` config persists in `/var/lib/tailscale/` across reboots.

## 5. First-run

Open `https://<hostname>.<tailnet>.ts.net` in a browser. Set the server password and create the
budget. Store the server password and the budget E2E password in the Proton Pass `machine-logins`
vault as Login items with username `actual-server@<hostname>` and `actual-budget@<hostname>`.

The budget E2E password is what encrypts the data at rest. Without it, no backup is recoverable.
