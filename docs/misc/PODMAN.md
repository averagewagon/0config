# Podman in 0config

Notes on using home-manager's `services.podman` to run rootless containers on the selfhost server.

## Where things go

All container declarations live in [`modules/selfhost.nix`](../../modules/selfhost.nix). One module
is the single source of truth for every self-hosted service. The `selfhost` flake target adds it on
top of `base + dev + syncthing`.

Container data lives under `~/0selfhost/<app>/` on the host. This is separate from
`~/0everything/`, so containers cannot reach Syncthing-managed files.

Access is Tailscale-only. Each container binds to `127.0.0.1:<port>` and is exposed via
`tailscale serve` (see [SELFHOST_SETUP.md](../setup/SELFHOST_SETUP.md)).

## Adding a new container

```nix
services.podman.containers.<name> = {
  image = "docker.io/<org>/<image>:latest";
  autoStart = true;
  autoUpdate = "registry";
  ports = [ "127.0.0.1:<port>:<port>" ];
  volumes = [ "${config.home.homeDirectory}/0selfhost/<name>:/data" ];
};
```

Then update the activation block in the same module to create the data directory:

```nix
home.activation.selfhostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  run mkdir -p ${config.home.homeDirectory}/0selfhost/actual
  run mkdir -p ${config.home.homeDirectory}/0selfhost/<name>
'';
```

`home-manager switch` generates a `~/.config/systemd/user/podman-<name>.service` unit and starts it.

## Common options

- `image` - registry path with explicit tag. Always pin the registry (`docker.io/...`) to avoid
  ambiguity with quay or ghcr.
- `ports` - list of `<host-ip>:<host-port>:<container-port>` strings. Always bind to `127.0.0.1` so
  `tailscale serve` is the only ingress.
- `volumes` - list of `<host-path>:<container-path>[:ro|:z|:Z]` strings. Use `:z` if SELinux
  rejects bind-mounts (Rocky's default policy usually accepts rootless paths under `~`).
- `environment` - attrset of env vars. Use `environmentFile` for secrets so they don't end up in
  the Nix store.
- `autoUpdate = "registry"` - per-container; pulls the latest image on the global timer.
- `extraPodmanArgs` - escape hatch for flags the module doesn't model.
- `extraConfig` - escape hatch for raw quadlet INI sections.

## Auto-updates

The global `services.podman.autoUpdate` timer is set to `Sun *-*-* 04:00:00`. Each container with
`autoUpdate = "registry"` is included in the run. `podman image prune -f` follows automatically.

## Operating

Service status:

```bash
systemctl --user status podman-<name>.service
```

Logs:

```bash
journalctl --user -u podman-<name>.service -f
```

Restart after changing config and running `home-manager switch`:

```bash
systemctl --user restart podman-<name>.service
```

Pull a new image manually (bypassing the timer):

```bash
podman auto-update
```

## Caveats

- `loginctl enable-linger jhen` must be set on the host once. Without it, services stop when the
  user logs out and don't start at boot. Documented in SELFHOST_SETUP.md.
- The first `home-manager switch` after adding a container won't fetch the image until the service
  starts. If startup is slow, that's the pull.
- Removing a container from `selfhost.nix` and switching does not delete its data directory. Clean
  up `~/0selfhost/<name>/` by hand if needed.

## References

- [home-manager options for `services.podman`](https://nix-community.github.io/home-manager/options.xhtml#opt-services.podman.enable) -
  full option reference.
- [quadlet-nix home-manager options](https://seiarotg.github.io/quadlet-nix/home-manager-options.html) -
  alternative module with broader Quadlet coverage; useful as a cross-reference for Quadlet
  semantics even when sticking with home-manager's built-in.
- [Podman Quadlet documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) -
  the underlying systemd unit format both modules generate.
- [Rootless Podman setup with Home Manager](https://discourse.nixos.org/t/rootless-podman-setup-with-home-manager/58189) -
  worked example with a multi-container pod.
