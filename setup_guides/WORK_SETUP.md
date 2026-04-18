# Work Machine Setup

Supplement to the LAPTOP_SETUP.md - these steps isolate personal credentials from the work environment.

## 1. Generate a personal SSH key

```bash
ssh-keygen -t ed25519 -C "contact@joni.site" -f ~/.ssh/personal_key
```

Use a strong password from Bitwarden (personal vault). Upload the public key to [github.com/settings/keys](https://github.com/settings/keys).

## 2. Clone 0config using the personal SSH alias

The `github-personal` SSH host is configured by `work.nix` to route through `~/.ssh/personal_key`.

```bash
git clone git@github-personal:hello-joni/0config.git ~/0config
```
