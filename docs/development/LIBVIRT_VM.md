# Libvirt VM

A full virtual machine managed with libvirt. Uses cloud images so there's no installer to click
through, and `virsh` snapshots so reverting after a wedged experiment is one command.

## 1. One-time host setup

Layer libvirt and friends on the Silverblue host:

```bash
sudo rpm-ostree install \
  libvirt-daemon-config-network libvirt-daemon-driver-qemu \
  libvirt-client virt-install
sudo systemctl reboot
```

After reboot:

```bash
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
# log out and back in so the group takes effect
```

Sanity check:

```bash
virsh list --all
virsh net-list --all   # 'default' should be active
```

## 2. Download a base image

Cloud images, with their `--os-variant` flag and default user:

- Debian 12
  - `--os-variant`: `debian12`
  - Default user: `debian`
  - https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
- Ubuntu 24.04
  - `--os-variant`: `ubuntu24.04`
  - Default user: `ubuntu`
  - https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
- Fedora 43
  - `--os-variant`: `fedora43`
  - Default user: `fedora`
  - https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.5.x86_64.qcow2
- Rocky 9
  - `--os-variant`: `rocky9`
  - Default user: `rocky`
  - https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
- Arch
  - `--os-variant`: `archlinux`
  - Default user: `arch`
  - https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2

Download a base. Example with Debian:

```bash
sudo curl -L -o /var/lib/libvirt/images/debian-base.qcow2 \
  https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
```

The base image is read-only and reusable across as many VMs as you want.

## 3. Create the VM

Each VM gets its own copy-on-write overlay backed by the base. The `30G` is the cap the guest sees -
the overlay file is sparse, starts at a few hundred KB on disk, and grows only as the guest writes
data. Cloud-init's `growpart` resizes the guest's root partition to that cap on first boot.

Template:

```bash
sudo qemu-img create -f qcow2 -F qcow2 \
  -b /var/lib/libvirt/images/<base>.qcow2 \
  /var/lib/libvirt/images/<vm-name>.qcow2 30G
```

Example with Debian:

```bash
sudo qemu-img create -f qcow2 -F qcow2 \
  -b /var/lib/libvirt/images/debian-base.qcow2 \
  /var/lib/libvirt/images/sandbox.qcow2 30G
```

Then `virt-install` builds the libvirt definition and imports the disk. The `--cloud-init` flag
injects your SSH key into the image's default user on first boot.

Template (angle-bracketed fields vary per VM; everything below `--disk` is boilerplate):

```bash
virt-install \
  --name <vm-name> \
  --os-variant <variant> \
  --memory 4096 --vcpus 4 \
  --disk path=/var/lib/libvirt/images/<vm-name>.qcow2 \
  --import \
  --network network=default \
  --cloud-init clouduser-ssh-key=$HOME/.ssh/personal_key.pub \
  --graphics none --noautoconsole
```

Example with Debian:

```bash
virt-install \
  --name sandbox \
  --os-variant debian12 \
  --memory 4096 --vcpus 4 \
  --disk path=/var/lib/libvirt/images/sandbox.qcow2 \
  --import \
  --network network=default \
  --cloud-init clouduser-ssh-key=$HOME/.ssh/personal_key.pub \
  --graphics none --noautoconsole
```

Wait ~30s for cloud-init. Ask libvirt for the VM's IP:

```bash
virsh domifaddr sandbox
```

Copy the address from the output and SSH in as the image's default user:

```bash
ssh debian@<ip>
```

If SSH isn't reachable (cloud-init failed, network wedged), drop to the serial console:
`virsh console sandbox` (exit with `Ctrl-]`).

## 4. Snapshots

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

## 5. Lifecycle

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

# Prints the VM's IP addresses
# virsh domifaddr <vm-name>
virsh domifaddr sandbox
```

## 6. Teardown

Delete one VM (keeps the base image for reuse):

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
sudo rm /var/lib/libvirt/images/debian-base.qcow2
```
