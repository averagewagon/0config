# Distrobox

[Distrobox](https://distrobox.it/) runs a full Linux distribution in a container with host
integration (home directory, GPU, sockets).

Useful for things which can't easily be installed with Home Manager.

## Lifecycle

```bash
distrobox create -i <image> -n <name>
distrobox enter <name>
distrobox list
distrobox stop <name>
distrobox rm <name>
```

Files in `$HOME` are shared with the host, so editors and Nix-managed tools on the host work on the
same files you build with inside the box.

## Common images

```bash
distrobox create -i quay.io/toolbx/ubuntu-toolbox:latest -n ubuntu
distrobox create -i quay.io/toolbx-images/debian-toolbox:latest -n debian
distrobox create -i registry.fedoraproject.org/fedora-toolbox:latest -n fedora
distrobox create -i quay.io/toolbx/arch-toolbox:latest -n arch
distrobox create -i quay.io/toolbx-images/alpine-toolbox:latest -n alpine
distrobox create -i quay.io/toolbx-images/rockylinux-toolbox:latest -n rocky
```
