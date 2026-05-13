# Generic Setup

Steps to layer 0config onto a generic Linux machine, typically a sandbox VM or one-off cloud
instance where you just want the dev shell environment.

Two flake targets cover this:

- `generic-headless` - base + dev modules only
- `generic-graphical` - adds graphical.nix (Flatpak GUI apps, GNOME tweaks)

Both read `$USER`, `$HOME`, and the host's architecture at evaluation time, so they need `--impure`
and work on any user / host / architecture without a hardcoded entry in `flake.nix`.

## 1. Clone 0config

Clone over HTTPS, since this machine isn't expected to push:

```bash
git clone https://github.com/hello-joni/0config.git ~/0config
```

## 2. Install Nix

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

Restart the shell.

## 3. Activate Home Manager

```bash
nix-shell -p home-manager
home-manager switch --flake ~/0config#generic-headless -b backup --impure
```

Swap `generic-headless` for `generic-graphical` if you want the GUI apps.
