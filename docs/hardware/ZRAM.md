# Zram

Raises the default cap on Fedora's zram swap device for high-RAM machines.

zram is a compressed block device held in RAM that Fedora uses as swap. Under memory pressure, the
kernel pushes rarely-used pages into zram (compressing them) instead of writing to a disk swap
partition, which is much faster.

`zram-size` sets the maximum size of the compressed device, which also caps how much real RAM the
kernel will spend holding compressed pages. Fedora ships a conservative `min(ram / 2, 8192)` default
from when zram was new. Since zram only allocates backing memory as pages actually get compressed
into it, raising the cap is close to free when the system isn't under pressure.

Pick a size and write it to `/etc/systemd/zram-generator.conf`:

```bash
printf '[zram0]\nzram-size = ram\n' | sudo tee /etc/systemd/zram-generator.conf
```

Setting the zram size to `ram` means the full size of memory can be used as compressed block
storage. Under sustained heavy swap pressure the kernel could fill zram and shrink the working set,
but on desktop/laptop workloads that rarely comes up and the alternative (earlier OOM or disk swap)
is usually worse.

In scenarios where thrash is undesirable, and fail-fast behavior around memory limits is desired,
then conventional engineering advice is to disable swap altogether. Kubernetes does this, for
example.

Apply without rebooting:

```bash
sudo modprobe zram
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service
```

Verify:

```bash
swapon --show
zramctl
```
