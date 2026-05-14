# Libvirt Root VM

A full virtual machine managed by libvirt's system instance. VMs run as root through `libvirtd`, get
real DHCP/DNS from a libvirt-managed bridge (`virbr0`), and reach each other and the host over that
bridge with full IPv4 + IPv6 routing through the host's kernel.

## 1. One-time host setup

Layer libvirt and friends on the Silverblue host:

```bash
sudo rpm-ostree install \
  qemu-kvm libvirt-client libvirt-daemon-driver-qemu \
  libvirt-daemon-driver-storage-core libvirt-daemon-config-network virt-install
sudo systemctl reboot
```

Enable the modular libvirt sockets and start the default NAT network:

```bash
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket
sudo virsh net-start default
sudo virsh net-autostart default
```

Sanity check:

```bash
sudo virsh list --all
sudo virsh net-list --all
```

The first should print an empty VM table; the second should show `default` as active + autostart
yes.

## 2. Download the base image

Use the Debian `generic` cloud image, not `genericcloud`. The genericcloud variant ships a
stripped-down kernel that disables many device drivers, including the one needed to read the
cloud-init seed CD-ROM. cloud-init then silently fails to apply any of your configuration.

```bash
sudo curl -L -o /var/lib/libvirt/images/debian-13-generic.qcow2 \
  https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2
```

The base image is read-only and reusable across as many VMs as you want.

## 3. Write the cloud-init seed

The seed is a small ISO holding two YAML files (`user-data` and `meta-data`) that cloud-init reads
on first boot. `user-data` defines the VM's user account and SSH keys; `meta-data` carries an
`instance-id` that cloud-init's NoCloud datasource requires.

```bash
mkdir -p /tmp/sandbox-seed
```

```bash
bash -c 'cat > /tmp/sandbox-seed/user-data <<EOF
#cloud-config
users:
  - name: debian
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat ~/.ssh/id_ed25519.pub)
ssh_pwauth: true
password: test123
chpasswd: { expire: false }
EOF'
```

`ssh_pwauth` + `password` set up a console-login fallback so you can `virsh console` into the VM as
`debian` if SSH ever fails. Remove those lines if you don't want them.

```bash
bash -c 'cat > /tmp/sandbox-seed/meta-data <<EOF
instance-id: sandbox
local-hostname: sandbox
EOF'
```

Build the seed ISO into the system images directory:

```bash
sudo xorriso -as mkisofs -output /var/lib/libvirt/images/sandbox-seed.iso \
  -volid cidata -joliet -rock /tmp/sandbox-seed/user-data /tmp/sandbox-seed/meta-data
```

## 4. Create the VM

Each VM gets its own copy-on-write overlay backed by the base. The `30G` is the cap the guest sees;
the overlay file is sparse, starts a few hundred KB on disk, and grows only as the guest writes
data.

```bash
sudo qemu-img create -f qcow2 -F qcow2 \
  -b /var/lib/libvirt/images/debian-13-generic.qcow2 \
  /var/lib/libvirt/images/sandbox.qcow2 30G
```

`virt-install --import` builds the libvirt definition around the overlay and attaches the seed ISO
as a CD-ROM. `--network network=default` puts the VM on the libvirt-managed `virbr0` bridge.

```bash
sudo virt-install \
  --connect qemu:///system \
  --name sandbox \
  --os-variant debian13 \
  --memory 4096 --vcpus 4 \
  --disk path=/var/lib/libvirt/images/sandbox.qcow2 \
  --disk path=/var/lib/libvirt/images/sandbox-seed.iso,device=cdrom \
  --import \
  --network network=default \
  --graphics none --noautoconsole
```

Wait ~30s for cloud-init, then ask libvirt for the VM's IP and SSH in:

```bash
sudo virsh domifaddr sandbox
ssh debian@<ip-from-output>
```

If SSH isn't reachable, drop to the serial console (`sudo virsh console sandbox`, exit with
`Ctrl-]`) and log in as `debian` with the password from your user-data.

## 5. Snapshots

```bash
# Saves a new snapshot of the VM as it is right now
sudo virsh snapshot-create-as sandbox clean

# Lists all snapshots taken of this VM
sudo virsh snapshot-list sandbox

# Rewinds the VM to a named snapshot, discarding everything after
sudo virsh snapshot-revert sandbox clean

# Removes a saved snapshot (the VM itself is unaffected)
sudo virsh snapshot-delete sandbox clean
```

Snapshots are internal to the qcow2 overlay, so they cost only the delta from the snapshot point.
Take one before any change you might want to undo wholesale.

## 6. Lifecycle

```bash
# Boots a stopped VM
sudo virsh start sandbox

# Sends an ACPI shutdown signal so the guest exits cleanly
sudo virsh shutdown sandbox

# Force-stops the VM immediately (like pulling the power cord)
sudo virsh destroy sandbox

# Attaches to the VM's serial console (exit with Ctrl-])
sudo virsh console sandbox

# Prints the VM's IP addresses (DHCP from the libvirt bridge)
sudo virsh domifaddr sandbox
```

## 7. Teardown

Delete one VM:

```bash
# Force-stops the VM if it's still running
sudo virsh destroy sandbox

# Removes the VM's libvirt definition along with its overlay disk and snapshot metadata
sudo virsh undefine sandbox --remove-all-storage --snapshots-metadata

# Remove the seed ISO (libvirt's --remove-all-storage skips read-only disks)
sudo rm /var/lib/libvirt/images/sandbox-seed.iso
```

Delete the base image too, only when no other overlay still backs onto it:

```bash
sudo rm /var/lib/libvirt/images/debian-13-generic.qcow2
```
