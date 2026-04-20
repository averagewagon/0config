# Intel GPU Codecs

H.264/H.265 hardware decode on Intel GPUs (Broadwell and newer), Fedora Silverblue.

Fedora strips patented codecs from `ffmpeg-free`. Swap it for the RPM Fusion build and add `intel-media-driver` (iHD, the modern VA-API driver; pre-Broadwell hardware uses `libva-intel-driver` / i965 instead). Requires RPM Fusion repos (step 4 of [LAPTOP_SETUP.md](../LAPTOP_SETUP.md)).

```bash
sudo rpm-ostree override remove \
  ffmpeg-free libavcodec-free libavfilter-free libavformat-free \
  libavutil-free libpostproc-free libswresample-free libswscale-free \
  libavdevice-free --install ffmpeg

sudo rpm-ostree install intel-media-driver libva-utils
systemctl reboot
```

Verify:

```bash
vainfo | grep -E "VAProfileH264|VAProfileHEVC"
ffmpeg -codecs 2>/dev/null | grep -E "h264|aac|hevc"
```

`vainfo` driver name should be `Intel iHD`.
