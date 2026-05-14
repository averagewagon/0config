# Libvirt VM

A full virtual machine managed with libvirt. Uses an installer ISO once to build a base image, then
copy-on-write overlays for cheap throwaway sandboxes. `virsh` snapshots so reverting after a wedged
experiment is one command.

VMs run rootless using user-mode networking (passt), so each VM gets its own isolated network with
the host as gateway. You can run several side-by-side, but they can't reach each other on a shared
subnet. If you need VM-to-VM connectivity, layer Tailscale or WireGuard inside the guests.

## 1. One-time host setup

Layer libvirt and friends on the Silverblue host:

```bash
sudo rpm-ostree install \
  qemu-kvm libvirt-client libvirt-daemon-driver-qemu \
  libvirt-daemon-driver-storage-core virt-install virt-viewer passt
sudo systemctl reboot
```

Sanity check:

```bash
virsh list --all
```

Should print an empty table.

## 2. Download an installer ISO

Installer ISOs, with their `--os-variant` flag:

- Debian 12
  - `--os-variant`: `debian12`
  - https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.10.0-amd64-netinst.iso
- Ubuntu Server 24.04
  - `--os-variant`: `ubuntu24.04`
  - https://releases.ubuntu.com/24.04/ubuntu-24.04.1-live-server-amd64.iso
- Fedora 43 Server
  - `--os-variant`: `fedora43`
  - https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-dvd-x86_64-43-1.5.iso
- Rocky 9 minimal
  - `--os-variant`: `rocky9`
  - https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-minimal.iso

Download into your image directory. Example with Debian:

```bash
mkdir -p ~/.local/share/libvirt/images
curl -L -o ~/.local/share/libvirt/images/debian-netinst.iso \
  https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.10.0-amd64-netinst.iso
```

## 3. Install the base VM

A one-time interactive install. The resulting qcow2 becomes the reusable base image - every future
sandbox is a copy-on-write overlay backed by it.

Template (angle-bracketed fields vary per distro):

```bash
virt-install \
  --name <distro>-base \
  --os-variant <variant> \
  --memory 2048 --vcpus 2 \
  --disk path=$HOME/.local/share/libvirt/images/<distro>-base.qcow2,size=20 \
  --network passt,portForward=2222:22 \
  --location $HOME/.local/share/libvirt/images/<iso>
```

Example with Debian:

```bash
virt-install \
  --name debian-base \
  --os-variant debian12 \
  --memory 2048 --vcpus 2 \
  --disk path=$HOME/.local/share/libvirt/images/debian-base.qcow2,size=20 \
  --network passt,portForward=2222:22 \
  --location $HOME/.local/share/libvirt/images/debian-netinst.iso
```

`virt-viewer` opens a graphical console for the installer. Walk through it:

- Set a hostname
- Create a user with a password
- Select the SSH server task (Debian's `tasksel`) so `openssh-server` is included
- Use the whole virtual disk for partitioning

Once the install completes and the VM reboots, shut it down:

```bash
virsh shutdown <distro>-base
```

Optional - undefine the install-time VM but keep its disk, since the qcow2 is all you need going
forward:

```bash
virsh undefine <distro>-base
```

The base image is now reusable across as many sandbox VMs as you want.

## 4. Create a sandbox

Each sandbox gets its own copy-on-write overlay backed by the base. The `30G` is the cap the guest
sees - the overlay file is sparse, starts a few hundred KB on disk, and grows only as the guest
writes data.

Template:

```bash
qemu-img create -f qcow2 -F qcow2 \
  -b ~/.local/share/libvirt/images/<distro>-base.qcow2 \
  ~/.local/share/libvirt/images/<vm-name>.qcow2 30G
```

Example with Debian:

```bash
qemu-img create -f qcow2 -F qcow2 \
  -b ~/.local/share/libvirt/images/debian-base.qcow2 \
  ~/.local/share/libvirt/images/sandbox.qcow2 30G
```

Then `virt-install --import` builds the libvirt definition around the overlay. The `portForward`
maps a host port to the VM's SSH port - each running VM needs a unique host port.

Template (everything below `--disk` is boilerplate except the host port):

```bash
virt-install \
  --name <vm-name> \
  --os-variant <variant> \
  --memory 4096 --vcpus 4 \
  --disk path=$HOME/.local/share/libvirt/images/<vm-name>.qcow2 \
  --import \
  --network passt,portForward=<host-port>:22 \
  --graphics none --noautoconsole
```

Example with Debian:

```bash
virt-install \
  --name sandbox \
  --os-variant debian12 \
  --memory 4096 --vcpus 4 \
  --disk path=$HOME/.local/share/libvirt/images/sandbox.qcow2 \
  --import \
  --network passt,portForward=2222:22 \
  --graphics none --noautoconsole
```

Wait ~15s for boot, then SSH in with the user and password you set during install:

```bash
ssh -p 2222 <user>@127.0.0.1
```

## 5. Snapshots

```bash
# Saves a new snapshot of the VM as it is right now
# virsh snapshot-create-as <vm-name> <snapshot-name>
virsh snapshot-create-as sandbox clean

# Lists all snapshots taken of this VM
# virsh snapshot-list <vm-name>
virsh snapshot-list sandbox

# Rewinds the VM to a named snapshot, discarding everything after
# virsh snapshot-revert <vm-name> <snapshot-name>
virsh snapshot-revert sandbox clean

# Removes a saved snapshot (the VM itself is unaffected)
# virsh snapshot-delete <vm-name> <snapshot-name>
virsh snapshot-delete sandbox clean
```

Snapshots are internal to the qcow2 overlay, so they cost only the delta from the snapshot point.
Take one before any change you might want to undo wholesale.

## 6. Lifecycle

```bash
# Boots a stopped VM
# virsh start <vm-name>
virsh start sandbox

# Sends an ACPI shutdown signal so the guest exits cleanly
# virsh shutdown <vm-name>
virsh shutdown sandbox

# Force-stops the VM immediately (like pulling the power cord)
# virsh destroy <vm-name>
virsh destroy sandbox

# Attaches to the VM's serial console (exit with Ctrl-])
# virsh console <vm-name>
virsh console sandbox
```

## 7. Teardown

Delete one sandbox (keeps the base image for reuse):

```bash
# Force-stops the VM if it's still running
# virsh destroy <vm-name>
virsh destroy sandbox

# Removes the VM's libvirt definition along with its disk files and snapshot metadata
# virsh undefine <vm-name> --remove-all-storage --snapshots-metadata
virsh undefine sandbox --remove-all-storage --snapshots-metadata
```

Delete the base image too, only when no other overlay still backs onto it:

```bash
rm ~/.local/share/libvirt/images/debian-base.qcow2
```
