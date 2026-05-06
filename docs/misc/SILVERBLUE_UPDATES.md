# Silverblue Major Version Upgrade

Runbook for rebasing a Silverblue laptop from Fedora N to N+1.

Layered RPM Fusion release packages are version-locked to the current Fedora
(`rpmfusion-free-release-43-1.noarch` requires `system-release(43)`). On rebase that dependency
disappears and depsolve fails. The release packages must be swapped for their N+1 versions in the
same transaction as the rebase.

## 1. Update current major version first

```bash
sudo rpm-ostree upgrade
rpm-ostree status
```

Reboot first if `upgrade` pulled anything. `State:` must be `idle` before proceeding; if
`gnome-software` is mid-transaction, wait or run `sudo rpm-ostree cancel`.

## 2. Get the new RPM Fusion release URLs

Copy the two RPM URLs for Fedora N+1 from <https://rpmfusion.org/Configuration>:

```
https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-<N+1>.noarch.rpm
https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-<N+1>.noarch.rpm
```

## 3. Rebase

```bash
sudo rpm-ostree rebase fedora:fedora/<N+1>/x86_64/silverblue \
  --uninstall rpmfusion-free-release \
  --uninstall rpmfusion-nonfree-release \
  --install <FREE_URL> \
  --install <NONFREE_URL>
```

The `--install` arguments must be HTTPS URLs. Bare names (`rpmfusion-free-release`) resolve against
currently-configured repos, which still serve the F(N) release package and reproduce the depsolve
error.

Other layered packages and base-package removals re-resolve against F(N+1) RPM Fusion automatically.

## 4. Reboot

```bash
systemctl reboot
```

## 5. Verify

```bash
rpm-ostree status
```

Active deployment should be on F(N+1). F(N) remains as the rollback.

## Rollback

Pick the previous entry in the GRUB boot menu, or:

```bash
sudo rpm-ostree rollback
systemctl reboot
```

## References

- [Updates, Upgrades & Rollbacks](https://docs.fedoraproject.org/en-US/atomic-desktops/updates-upgrades-rollbacks/) -
  official Fedora Atomic Desktops upgrade procedure
- [Upgrading Fedora Silverblue with RPMFusion packages](https://discussion.fedoraproject.org/t/upgrading-fedora-silverblue-with-rpmfusion-packages/44144) -
  source of the combined-transaction approach
