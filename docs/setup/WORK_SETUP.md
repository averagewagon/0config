# Work Machine Setup

Supplement to [LAPTOP_SETUP.md](./LAPTOP_SETUP.md)

## 1. SSH keys

See [SSH_KEYS.md](./credentials/SSH_KEYS.md) for more info.

The strategy for SSH keys here is to keep work and personal keys separate.

```bash
# Create a new Proton Pass login: ssh-keys/<hostname>-personal-key
# Generate a password in Proton Pass for the new key
ssh-keygen -t ed25519 -C "contact@joni.site" -f ~/.ssh/$(hostname)-personal-key
# Adding the key to the ssh-agent for 8 hours
ssh-add -t 8h ~/.ssh/$(hostname)-personal-key
cat ~/.ssh/$(hostname)-personal-key.pub  # store in Proton Pass item; upload to personal GitHub
```

```bash
# Create a new Proton Pass login: ssh-keys/<hostname>-work-key
# Generate a password in Proton Pass for the new key
ssh-keygen -t ed25519 -C "jonathan.hendrickson@bonsairobotics.ai" -f ~/.ssh/$(hostname)-work-key
# Adding the key to the ssh-agent for 8 hours
ssh-add -t 8h ~/.ssh/$(hostname)-work-key
# store in Proton Pass item; upload to work GitHub
cat ~/.ssh/$(hostname)-work-key.pub
```

Upload `<hostname>-personal-key.pub` to [github.com/settings/keys](https://github.com/settings/keys)
and `<hostname>-work-key.pub` to the company GitHub.

## 2. Clone 0config using the personal SSH alias

The `github-personal` SSH host is configured by `work.nix` to route through `~/.ssh/$(hostname)-personal-key`.

```bash
git clone git@github-personal:hello-joni/0config.git ~/0config
```
