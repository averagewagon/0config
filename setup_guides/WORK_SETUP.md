# Work Machine Setup

Supplement to [LAPTOP_SETUP.md](./LAPTOP_SETUP.md)

## 1. SSH keys

See [SSH_KEYS.md](./credentials/SSH_KEYS.md) for more info.

The strategy for SSH keys here is to keep work and personal keys separate.

```bash
# Create a new BW login: ssh/<hostname>_personal_key
# Generate a password in Bitwarden for the new key
ssh-keygen -t ed25519 -C "contact@joni.site" -f ~/.ssh/personal_key
# Adding the key to the ssh-agent for 8 hours
ssh-add -t 8h ~/.ssh/personal_key
cat ~/.ssh/personal_key.pub  # store in BW item; upload to personal GitHub
```

```bash
# Create a new BW login: ssh/<hostname>_work_key
# Generate a password in Bitwarden for the new key
ssh-keygen -t ed25519 -C "jonathan.hendrickson@bonsairobotics.ai" -f ~/.ssh/work_key
# Adding the key to the ssh-agent for 8 hours
ssh-add -t 8h ~/.ssh/work_key
# store in BW item; upload to work GitHub
cat ~/.ssh/work_key.pub
```

Upload `personal_key.pub` to [github.com/settings/keys](https://github.com/settings/keys) and `work_key.pub` to the company GitHub.

## 2. Clone 0config using the personal SSH alias

The `github-personal` SSH host is configured by `work.nix` to route through `~/.ssh/personal_key`.

```bash
git clone git@github-personal:hello-joni/0config.git ~/0config
```
