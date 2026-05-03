# Tailscale Exit Node

Steps to turn a Rocky Linux server into a Tailscale exit node.

`tailscale up --advertise-exit-node` warns about IP forwarding and UDP GRO. Both warnings need
addressing for a working, performant exit node.

## 1. Enable IP forwarding

Required for the kernel to route packets between interfaces. Persistent across reboots via
`/etc/sysctl.d/`:

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

## 2. Enable UDP GRO forwarding

Throughput optimization for the network interface Tailscale routes through. Not persistent by
default; install via a systemd oneshot that runs after `network-online.target`:

```bash
sudo dnf install -y ethtool
sudo tee /etc/systemd/system/tailscale-udp-gro.service <<'EOF'
[Unit]
Description=Configure UDP GRO for Tailscale exit-node performance
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " "); ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off'

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now tailscale-udp-gro.service
```

## 3. Advertise the exit node

```bash
sudo tailscale up --advertise-exit-node --ssh
```

The earlier warnings should be gone.

## 4. Approve in the admin console

In <https://login.tailscale.com/admin/machines>, find the host, open Edit route settings, check "Use
as exit node", Save.

## 5. Use it from a client

```bash
sudo tailscale up --exit-node=<hostname>
curl -v https://example.com   # confirm traffic actually flows
```

To stop using it:

```bash
sudo tailscale up --exit-node=
```

## References

- [Set up an exit node](https://tailscale.com/kb/1103/exit-nodes) - official setup guide
- [Performance best practices](https://tailscale.com/kb/1320/performance-best-practices) - source of
  the UDP GRO tuning
