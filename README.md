# 0config

Home Manager configuration for my machines.

## Activation

```bash
home-manager switch --flake ~/0config#laptop
home-manager switch --flake ~/0config#server
home-manager switch --flake ~/0config#phone
home-manager switch --flake ~/0config#work
```

## Maintenance

Updating Fedora Silverblue packages:
```bash
rpm-ostree upgrade
systemctl reboot
```

Updating Fedora packages:
```bash
sudo dnf upgrade
```

Updating Debian packages:
```bash
sudo apt update && sudo apt upgrade
```

Updating Nix (run switch command after):
```bash
nix flake update --flake ~/0config
```

Garbage collecting Nix store:
```bash
nix-collect-garbage -d
```
