# AMD GPU Codecs

H.264/H.265 hardware decode on AMD GPUs, Fedora Silverblue.

Fedora strips patented codecs from `mesa-va-drivers` and `ffmpeg-free`. Swap both for RPM Fusion builds. Requires RPM Fusion repos (step 4 of [LAPTOP_SETUP.md](../LAPTOP_SETUP.md)).

```bash
sudo rpm-ostree override remove \
  ffmpeg-free libavcodec-free libavfilter-free libavformat-free \
  libavutil-free libpostproc-free libswresample-free libswscale-free \
  libavdevice-free --install ffmpeg

sudo rpm-ostree install mesa-va-drivers-freeworld libva-utils
systemctl reboot
```

Verify:

```bash
vainfo | grep -E "VAProfileH264|VAProfileHEVC"
ffmpeg -codecs 2>/dev/null | grep -E "h264|aac|hevc"
```
